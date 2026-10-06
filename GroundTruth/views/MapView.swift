//
//  MapView.swift
//  GroundTruth
//
//  Created by Aryan Cyrus  on 15/9/2026.
//

import SwiftUI
import MapKit

struct MapView: View {
    private static let initialRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: -37.8136, longitude: 144.9631) //Melbourne, the city of assholes
        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    )
    
    @State private var cameraPosition: MapCameraPosition = .region(initialRegion)
    @State private var currentRegion = initialRegion
    
    @State private var searchText = ""
    @State private var showZonesLayer = true
    @State private var showOverlaysLayer = false
    @State private var selectedAddress: String?
    @State private var selectedCoordinate: CLLocationCoordinate2D
    
    @StateObject private var planningService = VicmapPlanningService()
    @State private var zoneFeatures: [PlanningFeature] = []
    @State private var overlayFeatures: [PlanningFeature] = []
    @State private var selectedPlanningInfo: PropertyPlanningInfo?
    @State private var isLoadingPlanningInfo = false
    @State private var viewportFetchTask: Task<Void, Never>?
    
    var body: some View{
        NavigationStack{
            ZStack(alignment: .top){
                Map(position: $cameraPosition){
                    if showZonesLayer {
                        ForEach(zoneFeatures) { feature in
                            ForEach(Array(feature.polygons.enumerated()), id: \.offset){_, polygon in
                                let color = PlanningZoneStyle.color(forZoneCode: feature.properties.zoneCode)
                                MapPolygon(polygon)
                                    .foregroundStyle(color.opacity(0.35))
                                    .stroke(color, lineWidth: 1)
                            }
                        }
                    }
                    
                    if showOverlaysLayer{
                        ForEach(overlayFeatures){ feature in
                            ForEach(Array(feature.polygons.enumerated()), id: \.offset){_, polygon in
                                MapPolygon(polygon)
                                    .foregroundStyle(.clear)
                                    .stroke(.brown, lineWidth: 2)
                            }
                        }
                    }
                    
                    if let selectedAddress, let selectedCoordinate {
                        Marker(selectedAddress, systemImage: "mappin", coordinate: selectedCoordinate)
                            .tint(.red)
                    }
                }
                .mapControls {
                    MapCompass()
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
                .overlay(alignment: .bottomTrailing)
                
            }
        }
    }
}
