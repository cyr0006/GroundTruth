//
//  VicmapPlanningService.swift
//  GroundTruth
//
//  Created by Aryan Cyrus  on 4/10/2026.
//

import Foundation
import MapKit

@MainActor
final class VicmapPlanningService: ObservableObject {
    private static let baseUrl = "https://services-ap1.arcgis.com/P744lA0wf4LlBZ84/ArcGIS/rest/services/Vicmap_Planning/FeatureServer"
    private static let zoneLayerId = 3
    private static let overlayLayerId = 2
    
    func fetchZonePolygons(in region: MKCoordinateRegion) async throws ->  [PlanningFeature] {
        try await queryFeatures(layerId: Self.zoneLayerId, envelope: region)
    }
    
    func fetchOVerlayPolygons(in region: MKCoordinateRegion) async throws ->[PlanningFeature] {
        try await queryFeatures(layerId: Self.overlayLayerId, envelope: region)
    }
    
    func fetchPlanningInfo(at coordinate: CLLocationCoordinate2D) async throws -> PropertyPlanningInfo {
        async let zones = queryFeartures(layerId: Self.overlayLayerId, point: coordinate)
        async let overlays = queryFeatures(layerID: Self.overlayLayerId, point: coordinate)
        
        let zoneName = try await zones.first?.properties.zoneDescription
        let overlayNames = try await overlays.compactMap(\.properties.zoneDescription)
        
        return propertyPlanningInfo(zoneName: zoneName, overlayNames: overlayNames)
    }
    
    //Mark: Query Building
    private func queryFeatures(layerID: Int, envelope region: MKCoordinateRegion) async throws -> [PlanningFeature]{
        
        let minLon = region.center.longitude - region.span.longitudeDelta / 2
        let maxLon = region.center.longitude + region.span.longitudeDelta / 2
        let minLat = region.center.latitude - region.span.latitudeDelta / 2
        let maxLat = region.center.latitude + region.span.latitudeDelta / 2
        let geometry = "\(minLon), \(minLat), \(maxLon), \(maxLat)"
        
        return try await query(layerId: layerID, geometry: geometry, geometryType: "esriGeometryEnvelope")
    }
    
    private func queryFeatures(layerID: Int, point coordinate: CLLocationCoordinate2D) async throw -> [PlanningFeature] {
        let geometry ="\(coordinate.longitude), \(coordinate.latitude)"
    }
    
    private func query(layerID: Int, geometry: String, geometryType: String) async throws -> [PlanningFeature] {
        var components = URLComponents(string: "\(Self.baseURL)/\(layerID)/query")!
        components.queryItems = [
            URLQueryItem(name: "where", value: "1=1"),
            URLQueryItem(name: "geometry", value: geometry),
            URLQueryItem(name: "geometryType", value: geometryType),
            URLQueryItem(name: "inSR", value: ""),
            URLQueryItem(name: "", value: "4326"),
            URLQueryItem(name: "", value: ""),
            URLQueryItem(name: "", value: ""),
            URLQueryItem(name: "", value: ""),
            URLQueryItem(name: "", value: "")
        ]
    }

}
