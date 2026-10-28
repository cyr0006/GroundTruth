//
//  PlanningStyle.swift
//  GroundTruth
//
//  Created by Aryan Cyrus  on 4/10/2026.
//

import Foundation
import SwiftUI

enum PlanningStyle {
    enum ZoneCategory: String, CaseIterable, Identifiable, Hashable {
        case residential, commercial, industrial, publicUse, rural, mixedUse, other

        var id: String { rawValue }

        var label: String {
            switch self {
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

        var description: String {
            switch self {
            case .residential: return "Land set aside mainly for housing, at a range of densities."
            case .commercial: return "Land used for retail, offices, and other commercial activity."
            case .industrial: return "Land used for manufacturing, warehousing, and other industrial activity."
            case .publicUse: return "Public land such as parks, reserves, utilities, or conservation areas."
            case .rural: return "Farming, rural living, or conservation land outside the main urban area."
            case .mixedUse: return "Land allowing a mix of housing, retail, and commercial uses together."
            case .other: return "An uncategorised or less common planning zone."
            }
        }
    }

    enum OverlayCategory: String, CaseIterable, Identifiable, Hashable {
        case heritage, vegetationProtection, significantLandscape, environmentalSignificance,
             bushfireManagement, floodInundation, designAndDevelopment, contributionsPlan,
             publicAcquisition, other

        var id: String { rawValue }

        var label: String {
            switch self {
            case .heritage: return "Heritage (HO)"
            case .vegetationProtection: return "Vegetation Protection (VPO)"
            case .significantLandscape: return "Significant Landscape (SLO)"
            case .environmentalSignificance: return "Environmental Significance (ESO)"
            case .bushfireManagement: return "Bushfire Management (BMO)"
            case .floodInundation: return "Flood / Inundation"
            case .designAndDevelopment: return "Design & Development (DDO)"
            case .contributionsPlan: return "Contributions Plan"
            case .publicAcquisition: return "Public Acquisition (PAO)"
            case .other: return "Other"
            }
        }

        var color: Color {
            switch self {
            case .heritage: return .brown
            case .vegetationProtection: return .green
            case .significantLandscape: return .teal
            case .environmentalSignificance: return .mint
            case .bushfireManagement: return .red
            case .floodInundation: return .indigo
            case .designAndDevelopment: return .purple
            case .contributionsPlan: return .yellow
            case .publicAcquisition: return .pink
            case .other: return .orange
            }
        }

        var description: String {
            switch self {
            case .heritage: return "Protects places of heritage significance — changes to buildings or demolition may need a permit."
            case .vegetationProtection: return "Protects native vegetation — removing or lopping trees may need a permit."
            case .significantLandscape: return "Protects valued landscapes or views — development must respect the area's character."
            case .environmentalSignificance: return "Protects environmentally sensitive areas such as waterways or habitats."
            case .bushfireManagement: return "Identifies bushfire-prone land — extra building and vegetation controls may apply."
            case .floodInundation: return "Identifies land at risk of flooding — development may need extra flood-resistant conditions."
            case .designAndDevelopment: return "Sets extra design requirements for buildings, like height or appearance, in this area."
            case .contributionsPlan: return "Requires development to contribute to local infrastructure, like roads or drainage."
            case .publicAcquisition: return "Marks land that may be acquired by a public authority in future, e.g. for a road or school."
            case .other: return "An uncategorised or less common planning overlay."
            }
        }
    }

    static func zoneCategory(forZoneCode code: String?) -> ZoneCategory {
        guard let code else { return .other }
        let normalized = normalize(code)
        guard !normalized.isEmpty else { return .other }

        if hasAnyPrefix(normalized, ["GRZ", "RGZ", "NRZ", "TZ", "RLZ", "LDRZ"]) {
            return .residential
        } else if hasAnyPrefix(normalized, ["C1Z", "C2Z"]) {
            return .commercial
        } else if hasAnyPrefix(normalized, ["IN1Z", "IN2Z", "IN3Z"]) {
            return .industrial
        } else if hasAnyPrefix(normalized, ["PUZ", "PCRZ", "PPRZ"]) {
            return .publicUse
        } else if hasAnyPrefix(normalized, ["FZ", "RCZ", "RUZ"]) {
            return .rural
        } else if hasAnyPrefix(normalized, ["MUZ"]) {
            return .mixedUse
        } else {
            return .other
        }
    }

    static func color(forZoneCode code: String?) -> Color {
        code == nil ? .gray : zoneCategory(forZoneCode: code).color
    }

    static func overlayCategory(forOverlayCode code: String?) -> OverlayCategory {
        guard let code else { return .other }
        let normalized = normalize(code)
        guard !normalized.isEmpty else { return .other }

        if hasAnyPrefix(normalized, ["HO"]) {
            return .heritage
        } else if hasAnyPrefix(normalized, ["VPO"]) {
            return .vegetationProtection
        } else if hasAnyPrefix(normalized, ["SLO"]) {
            return .significantLandscape
        } else if hasAnyPrefix(normalized, ["ESO"]) {
            return .environmentalSignificance
        } else if hasAnyPrefix(normalized, ["BMO"]) {
            return .bushfireManagement
        } else if hasAnyPrefix(normalized, ["LSIO", "SBO", "FO"]) {
            return .floodInundation
        } else if hasAnyPrefix(normalized, ["DDO"]) {
            return .designAndDevelopment
        } else if hasAnyPrefix(normalized, ["DCPO", "ICPO"]) {
            return .contributionsPlan
        } else if hasAnyPrefix(normalized, ["PAO"]) {
            return .publicAcquisition
        } else {
            return .other
        }
    }

    static func color(forOverlayCode code: String?) -> Color {
        code == nil ? .gray : overlayCategory(forOverlayCode: code).color
    }

    private static func normalize(_ code: String) -> String {
        code.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
    }

    private static func hasAnyPrefix(_ code: String, _ prefixes: [String]) -> Bool {
        prefixes.contains { code.hasPrefix($0) }
    }
}
