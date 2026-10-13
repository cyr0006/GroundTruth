//
//  PlanningZoneStyle.swift
//  GroundTruth
//
//  Created by Aryan Cyrus  on 4/10/2026.
//

import Foundation
import SwiftUI

enum PlanningStyle {
    enum ZoneCategory: String, CaseIterable, Identifiable, Hashable {
        case residential, commercial, industrial, publicUse, rural, mixedUse, other
        
        var id: String {rawValue}
        
        var label: String{
            switch self{
            case .residential: return "Residential"
            case .commercial: return "Commercial"
            case .industrial: return "Industrial"
            case .publicUse: return "Public Use / Conservation"
            case .rural: return "Rural"
            case .mixedUse: return "Mixed Use"
            case .other: return "Other"
            }
        }
        
        var color: Color {
            switch self {
            case .residential: return .orange
            case .commercial: return .blue
            case .industrial: return .purple
            case .publicUse: return .green
            case .rural: return .brown
            case .mixedUse: return .pink
            case .other: return .gray
            }
        }
    }

    enum OverlayCategory: String, CaseIterable, Identifiable, Hashable {
        case heritage, vegitationProtection, significantLandscape, environmentalSignificance, bushfireManagement, floodInundation, designAndDevelopment, contributionPlan, publicAcquisitiom, other
        
        var id: String {rawValue}
        
        var label: String{
            switch self {
            case .heritage: return "Heritage (HO)"
            case .vegitationProtection: return "Vegitation Protection (VPO)"
            case .significantLandscape: return "Significant Landscape (SLO)"
            case .environmentalSignificance: return "Environmental Significance (ESO)"
            case .bushfireManagement: return "Bushfire Management (BMO)"
            case .floodInundation: return "Flood / Inundation"
            case .designAndDevelopment: return "Design & Development (DDO)"
            case .contributionPlan: return "Contributions Plan"
            case .publicAcquisitiom: return "Public Acquisition (PAO)"
            case .other: return "Other"
            }
        }
        
        var color: Color {
            switch self{
            case .heritage: return .brown
            case .vegitationProtection: return .green
            case .significantLandscape: return .teal
            case .environmentalSignificance: return .mint
            case .bushfireManagement: return .red
            case .floodInundation: return .indigo
            case .designAndDevelopment: return .purple
            case .contributionPlan: return .yellow
            case .publicAcquisitiom: return .pink
            case .other: return .orange
            }
        }
    }
    
    static func zoneCategory(forZoneCode code: String?) -> ZoneCategory {
        guard let code, let prefix = codePrefix(of: code) else {return .other}
        
        switch prefix {
        case "GRZ", "RGZ", "NRZ", "TZ", "LDRZ":
            return .residential
        case "C1Z", "C2Z":
            return .commercial
        case "ON1Z", "IN2Z", "IN3Z":
            return .industrial
        case "PUZ", "PCRZ", "PPRZ":
            return .publicUse
        case "FZ", "RCZ", "RUZ":
               return .rural
        case "MUZ":
            return .mixedUse
            
        default:
            return .other
        }
    }
    
    static func color(forZoneCode code: String?) -> Color {
        code == nil ? .gray : zoneCategory(forZoneCode: code).color
    }
    
    static func overlayCategory(forOverlayCode code: String?) -> OverlayCategory{
        guard let code, let prefix = codePrefix(of: code) else {return .other}
        
        switch prefix {
        case "HO": return .heritage
        case "VPO": return .vegitationProtection
        case "SLO": return .significantLandscape
        case "ESO": return .environmentalSignificance
        case "BMO": return .bushfireManagement
        case "LSIO", "SBO", "FO": return .floodInundation
        case "DDO": return .designAndDevelopment
        case "DCPO", "ICPO": return .contributionPlan
        case "PAO": return .publicAcquisitiom
        default: return .other
        }
    }
    
    static func color(forOverlayCode code: String?) -> Color {
        code == nil ? .gray : overlayCategory(forOverlayCode: code).color
    }
    
    private static func codePrefix(of code: String) -> String? {
        let trimmed = code.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        let prefix = trimmed.prefix{!$0.isNumber}
        
        return prefix.isEmpty ? nil : String(prefix)
    }
}
    
//    static func color(forZoneCode code: String?) -> Color {
//        guard let code, let family = zoneFamily(of: code) else {return .gray}
//        return family
//    }
//    
//    private static func zoneFamily(of code: String) ->  Color? {
//        guard let prefix = codePrefix(of: code) else {return nil}
//        
//        switch prefix {
//        case "GRZ", "RGZ", "NRZ", "TZ", "RLZ", "LDRZ":
//            return .orange // residential family
//        case "C1Z", "C2Z":
//            return .blue //commercial family
//        case "IN1Z", "IN2Z", "IN3Z":
//            return .purple //industrial
//        case "PUZ", "PCRZ", "PPRZ":
//            return .green // public use/conservation
//        case "FZ", "RCZ", "RUZ":
//            return .brown // rural
//        case "MUZ":
//            return .pink //mixed use
//        default:
//            return nil
//        }
//    }
//    
//    private static func codePrefix(of code: String) -> String? {
//        let trimmed = code.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
//        let prefix = trimmed.prefix{!$0.isNumber}
//        return prefix.isEmpty ? nil : String(prefix)
//    }
//
//    static func color(forOverlayCode code: String?) -> Color {
//        guard let code, let prefix = codePrefix(of: code) else { return .gray }
//
//        switch prefix {
//        case "HO": return .brown     // Heritage Overlay
//        case "VPO": return .green    // Vegetation Protection Overlay
//        case "SLO": return .teal     // Significant Landscape Overlay
//        case "ESO": return .mint     // Environmental Significance Overlay
//        case "BMO": return .red      // Bushfire Management Overlay
//        case "LSIO", "SBO", "FO": return .indigo // Flood / Inundation Overlay
//        case "DDO": return .purple   // Design and Development Overlay
//        case "DCPO", "ICPO": return .yellow //
//        case "PAO": return .pink     // Public Acquisition Overlay
//        default: return .orange
//        }
//    }

