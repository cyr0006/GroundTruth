//
//  PlanningFeature.swift
//  GroundTruth
//
//  Created by Aryan Cyrus  on 4/10/2026.
//

import Foundation
import MapKit

struct PlanningFeatureProperties: Codable {
    let code: String?
    let description: String?
    let lga: String?
    let status: String?
    
    enum CodingKeys: String, CodingKey {
        case code = "zone_code"
        case description = "zone_description"
        case lga
        case status = "zone_status"
    }
}

struct PlanningFeature: Identifiable{
    let id: String
    let polygons: [MKPolygon]
    let properties: PlanningFeatureProperties
}

struct PropertyPlanningInfo {
    let zoneName: String?
    let overlayNames: [String]
}
