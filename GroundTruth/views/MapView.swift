//
//  MapView.swift
//  GroundTruth
//
//  Interactive map with address search and toggles for planning
//  zone / overlay layers. Layer rendering will be wired up to the
//  Vicmap Planning Data service later - for now the toggles just
//  drive placeholder UI state.
//

import SwiftUI
import MapKit

struct MapView: View {
    @State private var cameraPosition: MapCameraPosition = .region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: -37.8136, longitude: 144.9631), // Melbourne, VIC
            span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
        )
    )

    @State private var searchText = ""
    @State private var showZonesLayer = true
    @State private var showOverlaysLayer = false
    @State private var selectedAddress: String?

    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                Map(position: $cameraPosition) {
                    let lat: CLLocationDegrees = 37.90974
                    let long: CLLocationDegrees = 145.13173
                    let testCoordinate: CLLocationCoordinate2D = CLLocationCoordinate2D(latitude: lat, longitude: long)
                    if let selectedAddress {
                        Marker(selectedAddress, systemImage: "mappin", coordinate: testCoordinate)
                            .tint(.red)
                    }
                }
                .mapControls {
                    MapCompass()
                    MapScaleView()
                    MapUserLocationButton()
                }
                .ignoresSafeArea(edges: .bottom)

                VStack(spacing: 12) {
                    searchBar
                    if selectedAddress != nil {
                        propertyInfoCard
                    }
                }
                .padding()
            }
            .navigationTitle("Map")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Toggle(isOn: $showZonesLayer) {
                            Label("Planning Zones", systemImage: "square.on.square")
                        }
                        Toggle(isOn: $showOverlaysLayer) {
                            Label("Overlays", systemImage: "square.stack.3d.up")
                        }
                    } label: {
                        Image(systemName: "square.3.layers.3d")
                    }
                }
            }
        }
    }

    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
            TextField("Search an address", text: $searchText)
                .textFieldStyle(.plain)
                .onSubmit {
                    selectedAddress = searchText
                }
            if !searchText.isEmpty {
                Button {
                    searchText = ""
                    selectedAddress = nil
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(10)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
        .shadow(radius: 2)
    }

    private var propertyInfoCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(selectedAddress ?? "")
                .font(.headline)

            HStack(spacing: 8) {
                if showZonesLayer {
                    tagView("General Residential Zone", color: .blue)
                }
                if showOverlaysLayer {
                    tagView("Heritage Overlay", color: .brown)
                }
            }

            Text("Planning information for this property will appear here once Vicmap data is connected.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
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
    }
}

#Preview {
    MapView()
}
