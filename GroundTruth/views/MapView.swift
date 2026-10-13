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
    @State private var showZonesLayer = true
    @State private var showOverlaysLayer = false
    @State private var selectedAddress: String?
    @State private var selectedCoordinate: CLLocationCoordinate2D?

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
                .onChange(of: showZonesLayer){_, isOn in
                    if isOn {scheduleViewportFetch()} else {zoneFeatures = []}
                }
                .onChange(of: showOverlaysLayer){_, isOn in
                    if isOn {scheduleViewportFetch()} else {overlayFeatures = []}
                }
                .onTapGesture{screenPoint in
                    handleMapTap(at: screenPoint, proxy: proxy)
                }
                // bottomLeading, not bottomTrailing: MapUserLocationButton already sits
                // bottom-trailing, so this avoids stacking on top of it.
                .overlay(alignment: .bottomLeading) {
                    VStack(alignment: .leading, spacing: 6) {
                        if showOverlaysLayer {
                            overlayLegend
                        }
                    }
                    .padding()
                }
                .ignoresSafeArea(edges: .bottom)
                VStack(spacing: 12){
                    searchBar
                    if selectedAddress != nil {
                        propertyInfoCard
                    }
                }
                .padding()
            }
        }
        .navigationTitle("Map")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar{
            ToolbarItem(placement: .topBarTrailing){
                Menu{
                    Toggle(isOn: $showZonesLayer){
                        Label("Planning Zones", systemImage: "square.on.square")
                    }
                    Toggle(isOn: $showOverlaysLayer){
                        Label("Overlays", systemImage: "square.stack.3d.up")
                    }
                } label: {
                    Image(systemName: "square.3.layers.3d")
                }
            }
        }
        // This screen is pushed (from Home's "Search Address" quick action), not a
        // tab root, so the bottom tab bar would otherwise still show underneath it.
        .toolbar(.hidden, for: .tabBar)
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
            Text(selectedAddress ?? "")
                .font(.subheadline)
                .fontWeight(.semibold)
                .lineLimit(1)

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
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
        .shadow(radius: 2)
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
            let color = PlanningStyle.color(forZoneCode: feature.properties.code)
            return feature.polygons.enumerated().map {index, polygon in
                PlanningPolygonItem(id: "\(feature.id)-\(index)", polygon: polygon, color: color)

            }
        }
    }

    private var overlayPolygonItems: [PlanningPolygonItem] {
        overlayFeatures.flatMap { feature in
            let color = PlanningStyle.color(forOverlayCode: feature.properties.code)
            return feature.polygons.enumerated().map { index, polygon in
                PlanningPolygonItem(id: "\(feature.id)-\(index)", polygon: polygon, color: color)
            }
        }
    }

    private var overlayLegend: some View {
        let codes: [(String, Color)] = [
            ("Heritage (HO)", .brown), ("Vegetation Protection (VPO)", .green),
            ("Significant Landscape (SLO)", .teal), ("Environmental Significance (ESO)", .mint),
            ("Bushfire Management (BMO)", .red), ("Flood / Inundation", .indigo),
            ("Design & Development (DDO)", .purple), ("Other", .orange)
        ]
        return VStack(alignment: .leading, spacing: 4) {
            ForEach(codes, id: \.0) { label, color in
                HStack(spacing: 6) {
                    Circle().fill(color).frame(width: 8, height: 8)
                    Text(label).font(.caption2)
                }
            }
        }
        .padding(8)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8))
    }

}

#Preview {
    NavigationStack {
        MapView()
    }
}
