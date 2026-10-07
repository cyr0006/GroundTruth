//
//  VicmapPlanningService.swift
//  GroundTruth
//
//  Created by Aryan Cyrus  on 4/10/2026.
//

import Foundation
import MapKit
internal import Combine

@MainActor
final class VicmapPlanningService: ObservableObject {
    private static let baseURL = "https://services-ap1.arcgis.com/P744lA0wf4LlBZ84/ArcGIS/rest/services/Vicmap_Planning/FeatureServer"
    private static let zoneLayerId = 3
    private static let overlayLayerId = 2
    
    func fetchZonePolygons(in region: MKCoordinateRegion) async throws ->  [PlanningFeature] {
        try await queryFeatures(layerId: Self.zoneLayerId, envelope: region)
    }
    
    func fetchOverlayPolygons(in region: MKCoordinateRegion) async throws ->[PlanningFeature] {
        try await queryFeatures(layerId: Self.overlayLayerId, envelope: region)
    }
    
    func fetchPlanningInfo(at coordinate: CLLocationCoordinate2D) async throws -> PropertyPlanningInfo {
        async let zones = queryFeatures(layerId: Self.overlayLayerId, point: coordinate)
        async let overlays = queryFeatures(layerId: Self.overlayLayerId, point: coordinate)
        
        let zoneName = try await zones.first?.properties.description
        let overlayNames = try await overlays.compactMap(\.properties.description)
        
        return PropertyPlanningInfo(zoneName: zoneName, overlayNames: overlayNames)
    }
    
    //Mark: Query Building
    private func queryFeatures(layerId: Int, envelope region: MKCoordinateRegion) async throws -> [PlanningFeature]{
        
        let minLon = region.center.longitude - region.span.longitudeDelta / 2
        let maxLon = region.center.longitude + region.span.longitudeDelta / 2
        let minLat = region.center.latitude - region.span.latitudeDelta / 2
        let maxLat = region.center.latitude + region.span.latitudeDelta / 2
        let geometry = "\(minLon), \(minLat), \(maxLon), \(maxLat)"
        
        return try await query(layerId: layerId, geometry: geometry, geometryType: "esriGeometryEnvelope")
    }
    
    private func queryFeatures(layerId: Int, point coordinate: CLLocationCoordinate2D) async throws -> [PlanningFeature] {
        let geometry = "\(coordinate.longitude), \(coordinate.latitude)"
        return try await query(layerId: layerId, geometry: geometry, geometryType: "esriGerometryPoint")
    }
    

    private func query(layerId: Int, geometry: String, geometryType: String) async throws -> [PlanningFeature] {
        var components = URLComponents(string: "\(Self.baseURL)/\(layerId)/query")!
        components.queryItems = [
            URLQueryItem(name: "where", value: "1=1"),
            URLQueryItem(name: "geometry", value: geometry),
            URLQueryItem(name: "geometryType", value: geometryType),
            URLQueryItem(name: "inSR", value: "4326"),
            URLQueryItem(name: "spatialRel", value: "esriSpatialRelIntersects"),
            URLQueryItem(name: "outFields", value: "description,lga,zone_status"),
            URLQueryItem(name: "returnGeometry", value: "true"),
            URLQueryItem(name: "outSR", val
            URLQueryItem(name: "f", value: "geojson")
        ]

        let url = components.url!
        print("VicmapPlanningService: requesting \(url.absoluteString)")

        let (data, response) = try await URLSession.shared.data(from: url)
        if let httpResponse = response as?
            print("VicmapPlanningService: layer \(layerId) responded HTTP \(httpResponse.statusCode)")
        }
        warnIfTruncated(data, layerId: layerId)
        let features = try Self.decodeFeatu
        print("VicmapPlanningService: layer \(layerId) decoded \(features.count) feature(s)")
        return features
    }
    
    private func warnIfTruncated(_ data: Data, layerId: Int){
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              json["exceededTransferlimit"] as? Bool == true else {return}
        print("VicmapPlanningService: results truncated (exceededTransferLimit) for layer \(layerId)")
    }
    
    // MARK: - Decoding
    
    private static func decodeFeatures(from data: Data) throws -> [PlanningFeature]{
        let objects = try MKGeoJSONDecoder().decode(data)
        let decoder = JSONDecoder()
        
        return objects.compactMap{object -> PlanningFeature? in
            guard let feature = object as? MKGeoJSONFeature,
                  let propertiesData = feature.properties,
                  let properties = try? decoder.decode(PlanningFeatureProperties.self, from: propertiesData) else{
                return nil
            }
            
            
            
            let polygons = feature.geometry.flatMap { shape -> [MKPolygon] in
                switch shape {
                case let polygon as MKPolygon: return [polygon]
                case let multiPolygon as MKMultiPolygon: return multiPolygon.polygons
                default: return []
                }
            }
            
            guard !polygons.isEmpty else {return nil}
            
            return PlanningFeature(
                id: feature.identifier ?? UUID().uuidString,
                polygons: polygons,
                properties: properties
            )
            
        }
    }
}
