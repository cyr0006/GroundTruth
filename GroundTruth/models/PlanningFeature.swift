//
//  PlanningFeature.swift
//  GroundTruth
//
//  Created by Aryan Cyrus  on 4/10/2026.
//

import Foundation
import MapKit

struct PlanningFeatureProperties: Codable {
    let zoneCode: String?
    let zoneDescription: String?
    let lga: String?
    let zoneStatus: String?
    
    enum CodingKeys: String, CodingKey {
        case zoneCode = "zone_code"
        case zoneDescription = "zoneDescription"
        case lga
        case zoneStatus = "zone_status"
    }
}

struct PlanningFeature: Identifiable{
    let id: String
    let polygons: [MKPolygon]
    let properties: PlanningFeatureProperties
}

struct propertyPlanningInfo {
    let zoneName: String?
    let overlayNames: [String]
}
