//
//  MapView.swift
//  GroundTruth
//
//  Created by Aryan Cyrus  on 15/9/2026.
//

import SwiftUI
import MapKit
import CoreLocation

struct MapView: View {
    private static let initialRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: -37.8136, longitude: 144.9631),
        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    )

    @State private var cameraPosition: MapCameraPosition = .region(initialRegion)
    @State private var currentRegion = initialRegion

    @State private var searchText = ""
    @State private var enabledZoneCategories: Set<PlanningStyle.ZoneCategory> = Set(PlanningStyle.ZoneCategory.allCases)
    @State private var enabledOverlayCategories: Set<PlanningStyle.OverlayCategory> = []
    @State private var sheetDetent: PresentationDetent = .height(140)
    @State private var selectedAddress: String?
    @State private var selectedCoordinate: CLLocationCoordinate2D?
    @State private var showPropertyProfile = false

    @StateObject private var planningService = VicmapPlanningService()
    @State private var zoneFeatures: [PlanningFeature] = []
    @State private var overlayFeatures: [PlanningFeature] = []
    @State private var selectedPlanningInfo: PropertyPlanningInfo?
    @State private var isLoadingPlanningInfo = false
    @State private var viewportFetchTask: Task<Void, Never>?
    @State private var reverseGeocodeTask: Task<Void, Never>?

    private struct PlanningPolygonItem: Identifiable{
        let id: String
        let polygon: MKPolygon
        let color: Color
    }

    private var showZonesLayer: Bool { !enabledZoneCategories.isEmpty }
    private var showOverlaysLayer: Bool { !enabledOverlayCategories.isEmpty }

    var body: some View{
        ZStack(alignment: .top){
            MapReader {proxy in
                Map(position: $cameraPosition){
                    if showZonesLayer {
                        ForEach(zonePolygonItems) { item in
                            MapPolygon(item.polygon)
                                .foregroundStyle(item.color.opacity(0.35))
                                .stroke(item.color, lineWidth: 2)
                        }
                    }

                    if showOverlaysLayer{
                        ForEach(overlayPolygonItems) { item in
                            MapPolygon(item.polygon)
                                .foregroundStyle(.clear)
                                .stroke(item.color, lineWidth: 2)
                        }
                    }

                    if let selectedAddress, let selectedCoordinate {
                        Marker(selectedAddress, systemImage: "mappin", coordinate: selectedCoordinate)
                            .tint(.red)
                    }
                }

                // MapCompass dropped: its default top-trailing position collided with the
                // search bar / layer-toggle toolbar button in that same corner.
                .mapControls {
                    MapScaleView()
                    MapUserLocationButton()
                }
                .onMapCameraChange (frequency: .onEnd) { context in
                    currentRegion = context.region
                    scheduleViewportFetch()
                }
                .task{
                    scheduleViewportFetch()
                }
                .onChange(of: enabledZoneCategories){_, categories in
                    if !categories.isEmpty {scheduleViewportFetch()} else {zoneFeatures = []}
                }
                .onChange(of: enabledOverlayCategories){_, categories in
                    if !categories.isEmpty {scheduleViewportFetch()} else {overlayFeatures = []}
                }
                .onTapGesture{screenPoint in
                    handleMapTap(at: screenPoint, proxy: proxy)
                }
                .ignoresSafeArea(edges: .bottom)
            }

            if selectedAddress != nil {
                propertyInfoCard
                    .padding()
                    .onTapGesture {
                        showPropertyProfile = true
                    }
            }
        }
        .navigationTitle("Map")
        .navigationBarTitleDisplayMode(.inline)
        // This screen is pushed (from Home's "Search Address" quick action), not a
        // tab root, so the bottom tab bar would otherwise still show underneath it.
        .toolbar(.hidden, for: .tabBar)
        .sheet(isPresented: .constant(true)) {
            mapBottomPanel
                .presentationDetents([.height(140), .medium, .large], selection: $sheetDetent)
                .presentationDragIndicator(.visible)
                .presentationBackgroundInteraction(.enabled(upThrough: .medium))
                //.interactiveDismissDisabled()
                
        }
        .navigationDestination(isPresented: $showPropertyProfile) {
            PropertyProfileView(address: selectedAddress ?? "", planningInfo: selectedPlanningInfo)
        }
    }

    private var mapBottomPanel: some View {
        VStack(spacing: 0){
            searchBar
                .padding(.horizontal)
                .padding(.top, 8)
                .padding(.bottom, 12)

            ScrollView{
                VStack(alignment: .leading, spacing: 24){
                    categorySection(
                        title: "Planning Zones",
                        allSelected: allZonesSelectedBinding,
                        rows: PlanningStyle.ZoneCategory.allCases
                    ) { category in
                        categoryRow(
                            label: category.label,
                            color: category.color,
                            isOn: zoneCategoryBinding(for: category)
                        )
                    }

                    categorySection(
                        title: "Planning Overlays",
                        allSelected: allOverlaysSelectedBinding,
                        rows: PlanningStyle.OverlayCategory.allCases
                    ) { category in
                        categoryRow(
                            label: category.label,
                            color: category.color,
                            isOn: overlayCategoryBinding(for: category)
                        )
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 24)
            
            }
        }
    }

    private func categorySection<Category: Hashable & Identifiable, Content: View>(
        title: String,
        allSelected: Binding<Bool>,
        rows: [Category],
        @ViewBuilder row: @escaping (Category) -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 4){
            HStack{
                Text(title)
                    .font(.headline)
                Spacer()
                Button {
                    allSelected.wrappedValue.toggle()
                } label: {
                    HStack(spacing: 4){
                        Image(systemName: allSelected.wrappedValue ? "checkmark.square.fill" : "square")
                        Text("Select All")
                    }
                    .font(.caption)
                }
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)
            }
            .padding(.bottom, 4)

            VStack(spacing: 0){
                ForEach(rows) { category in
                    row(category)
                    if category.id != rows.last?.id {
                        Divider()
                    }
                }
            }
        }
    }

    private func categoryRow(label: String, color: Color, isOn: Binding<Bool>) -> some View {
        Button {
            isOn.wrappedValue.toggle()
        } label: {
            HStack(spacing: 10){
                Circle()
                    .fill(color)
                    .frame(width: 14, height: 14)
                Text(label)
                    .font(.subheadline)
                    .foregroundStyle(.primary)
                Spacer()
                Image(systemName: isOn.wrappedValue ? "checkmark.square.fill" : "square")
                    .foregroundStyle(isOn.wrappedValue ? color : .secondary)
            }
            .padding(.vertical, 8)
        }
        .buttonStyle(.plain)
    }

    private func zoneCategoryBinding(for category: PlanningStyle.ZoneCategory) -> Binding<Bool> {
        Binding(
            get: { enabledZoneCategories.contains(category) },
            set: { isOn in
                if isOn { enabledZoneCategories.insert(category) } else { enabledZoneCategories.remove(category) }
            }
        )
    }

    private func overlayCategoryBinding(for category: PlanningStyle.OverlayCategory) -> Binding<Bool> {
        Binding(
            get: { enabledOverlayCategories.contains(category) },
            set: { isOn in
                if isOn { enabledOverlayCategories.insert(category) } else { enabledOverlayCategories.remove(category) }
            }
        )
    }

    private var allZonesSelectedBinding: Binding<Bool> {
        Binding(
            get: { enabledZoneCategories.count == PlanningStyle.ZoneCategory.allCases.count },
            set: { isOn in
                enabledZoneCategories = isOn ? Set(PlanningStyle.ZoneCategory.allCases) : []
            }
        )
    }

    private var allOverlaysSelectedBinding: Binding<Bool> {
        Binding(
            get: { enabledOverlayCategories.count == PlanningStyle.OverlayCategory.allCases.count },
            set: { isOn in
                enabledOverlayCategories = isOn ? Set(PlanningStyle.OverlayCategory.allCases) : []
            }
        )
    }

    private var searchBar: some View {
        AddressSearchField(text: $searchText, placeholder: "Search an address", leadingIcon: "magnifyingglass"){ address, coordinate in
            selectedAddress = address
            selectedCoordinate = coordinate
            if let coordinate {
                withAnimation {
                    cameraPosition = .region(
                        MKCoordinateRegion(center: coordinate, span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01))
                    )
                }
                fetchPlanningInfo(at: coordinate)
            } else {
                selectedPlanningInfo = nil
            }
        }
        .onChange(of: searchText){_, newValue in
            if newValue.isEmpty{
                selectedAddress = nil
                selectedCoordinate = nil
                selectedPlanningInfo = nil
            }
        }
        .padding(10)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
        .shadow(radius: 2)
    }

    private var propertyInfoCard: some View{
        VStack(alignment: .leading, spacing: 6){
            HStack{
                Text(selectedAddress ?? "")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .lineLimit(1)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if isLoadingPlanningInfo{
                ProgressView()
            } else {
                // Horizontal scroll, not a wrapping HStack: an address with several
                // overlays was pushing this card tall enough to cover half the map.
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8){
                        if showZonesLayer {
                            tagView(
                                selectedPlanningInfo?.zoneName ?? "No Zone Data",
                                color: PlanningStyle.color(forZoneCode: selectedPlanningInfo?.zoneCode)
                            )
                        }
                        if showOverlaysLayer {
                            let overlayNames = selectedPlanningInfo?.overlayNames ?? []
                            let overlayCodes = selectedPlanningInfo?.overlayCodes ?? []

                            if overlayNames.isEmpty {
                                tagView("no overlays", color: .brown)
                            } else {
                                ForEach(Array(overlayNames.enumerated()), id: \.offset){ index, name in
                                    tagView(name, color: PlanningStyle.color(forOverlayCode: overlayCodes[index]))
                                }
                            }
                        }
                    }
                }
            }
            Text("Source: Vicmap Planning, data.vic.gov.au")
                .font(.caption2)
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .shadow(radius: 2)
        .background(.thinMaterial, in:RoundedRectangle(cornerRadius: 20))
    }

    private func tagView(_ text: String, color: Color) -> some View {
        Text(text)
            .font(.caption2)
            .fontWeight(.semibold)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(color.opacity(0.15), in: Capsule())
            .foregroundStyle(color)
            .fixedSize(horizontal: true, vertical: false)
    }

    private func scheduleViewportFetch(){
        viewportFetchTask?.cancel()
        guard showZonesLayer || showOverlaysLayer else {return}

        guard currentRegion.span.latitudeDelta < 0.5 else {
            zoneFeatures = []
            overlayFeatures = []
            return
        }

        viewportFetchTask = Task{
            try? await Task.sleep(for: .milliseconds(500))
            guard !Task.isCancelled else {return}

            if showZonesLayer {
                zoneFeatures = (try? await planningService.fetchZonePolygons(in: currentRegion)) ?? []
            }
            if showOverlaysLayer {
                overlayFeatures = (try? await planningService.fetchOverlayPolygons(in: currentRegion)) ?? []
            }
        }
    }

    private func fetchPlanningInfo(at coordinate: CLLocationCoordinate2D){
        isLoadingPlanningInfo = true
        selectedPlanningInfo = nil
        Task {
            defer {isLoadingPlanningInfo = false}
            selectedPlanningInfo = try? await planningService.fetchPlanningInfo(at: coordinate)
        }
    }

    private func handleMapTap(at point: CGPoint, proxy: MapProxy){
        guard let coordinate = proxy.convert(point, from: .local) else {return}

        searchText = ""
        selectedCoordinate = coordinate
        selectedAddress = "Resolving Addres"
        selectedPlanningInfo = nil
        fetchPlanningInfo(at: coordinate)

        reverseGeocodeTask?.cancel()
        reverseGeocodeTask = Task{
            let geocoder = CLGeocoder()
            let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
            let placemarks = try? await geocoder.reverseGeocodeLocation(location)
            guard !Task.isCancelled else {return}

            let resolved = placemarks?.first.flatMap {placemark in
                [placemark.subThoroughfare, placemark.thoroughfare, placemark.locality]
                    .compactMap{$0}
                    .joined(separator: " ")
            }
            selectedAddress = (resolved?.isEmpty == false) ? resolved : "Dropped Pin"
            searchText = selectedAddress ?? ""
        }
    }

    private var zonePolygonItems: [PlanningPolygonItem] {
        zoneFeatures.flatMap {feature in
            let category: PlanningStyle.ZoneCategory = PlanningStyle.zoneCategory(forZoneCode: feature.properties.code)
            guard enabledZoneCategories.contains(category) else {return [PlanningPolygonItem]()}
            let color = category.color
            return feature.polygons.enumerated().map {index, polygon in
                PlanningPolygonItem(id: "\(feature.id)-\(index)", polygon: polygon, color: color)
            }
        }
    }

    private var overlayPolygonItems: [PlanningPolygonItem] {
        overlayFeatures.flatMap { feature in
            let category = PlanningStyle.overlayCategory(forOverlayCode: feature.properties.code)
            guard enabledOverlayCategories.contains(category) else {return [PlanningPolygonItem]()}
            let color = category.color
            return feature.polygons.enumerated().map { index, polygon in
                PlanningPolygonItem(id: "\(feature.id)-\(index)", polygon: polygon, color: color)
            }
        }
    }

}

#Preview {
    NavigationStack {
        MapView()
    }
}
