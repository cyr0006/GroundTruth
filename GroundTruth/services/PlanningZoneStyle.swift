//
//  PlanningZoneStyle.swift
//  GroundTruth
//
//  Created by Aryan Cyrus  on 4/10/2026.
//

import Foundation
import SwiftUI

enum PlanningZoneStyle {
    static func color(forZoneCode code: String?) -> Color {
        guard let code, let family = zoneFamily(of: code) else {return .gray}
        return family
    }
    
    private static func zoneFamily(of code: String) ->  Color? {
        guard let prefix = zonePrefix(of: code) else {return nil}
        
        switch prefix {
        case "GRZ", "RGZ", "NRZ", "TZ", "RLZ", "LDRZ":
            return .orange // residential family
        case "C1Z", "C2Z":
            return .blue //commercial family
        case "IN1Z", "IN2Z", "IN3Z":
            return .purple //industrial
        case "PUZ", "PCRZ", "PPRZ":
            return .green // public use/conservation
        case "FZ", "RCZ", "RUZ":
            return .brown // rural
        case "MUZ":
            return .pink //mixed use
        default:
            return nil
        }
    }
    
    private static func zonePrefix(of code: String) -> String? {
        let trimmed = code.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        let prefix = trimmed.prefix{!$0.isNumber}
        return prefix.isEmpty ? nil : String(prefix)
    }
}
