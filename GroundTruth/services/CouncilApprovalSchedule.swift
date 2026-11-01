//
//  CouncilApprovalSchedule.swift
//  GroundTruth
//

import Foundation

/// Council approvals a residential project might need beyond planning/building permits,
/// with real Cardinia Shire Council fees (2026-27) where published. Re-verify against
/// Cardinia's current fee schedule when it updates - these are fixed council figures, not
/// a formula, same caveat as `PlanningPermitFeeClass`.
enum CouncilApprovalType: String, CaseIterable, Codable {
    case assetProtection = "asset_protection"
    case vehicleCrossing = "vehicle_crossing"
    case legalPointOfDischarge = "legal_point_of_discharge"
    case treeRemoval = "tree_removal"
    case septicTank = "septic_tank"

    var displayName: String {
        switch self {
        case .assetProtection: return "Asset Protection Permit"
        case .vehicleCrossing: return "Vehicle Crossing Permit"
        case .legalPointOfDischarge: return "Legal Point of Discharge"
        case .treeRemoval: return "Tree Removal Permit"
        case .septicTank: return "Septic Tank Permit"
        }
    }

    /// One sentence describing what triggers this approval, fed to the AI as classification
    /// guidance - kept here next to the fee so the two stay in sync.
    var guidance: String {
        switch self {
        case .assetProtection:
            return "Needed whenever building work could affect Council infrastructure - kerbs, footpaths, nature strips, drains - during construction. Applies to most building/renovation work, not just new builds."
        case .vehicleCrossing:
            return "Needed only when creating a new vehicle crossing/driveway or altering an existing one."
        case .legalPointOfDischarge:
            return "Needed when the project changes how stormwater drains from the property (new roof area, new hard surfaces, a new dwelling)."
        case .treeRemoval:
            return "Needed to remove an ordinary (non-overlay-protected) tree under the Tree Protection Local Law. If removal is instead triggered by a Vegetation Protection/Environmental Significance overlay, that's a planning permit matter, not this - don't double-count it here."
        case .septicTank:
            return "Needed only if the property is not connected to mains sewer and the project involves installing or altering a septic system."
        }
    }

    /// Fixed application fee, Cardinia Shire 2026-27 - nil where no published figure was found.
    var fee: Double? {
        switch self {
        case .assetProtection: return 388.00
        case .vehicleCrossing: return 156.30
        case .legalPointOfDischarge: return 244.70
        case .treeRemoval: return 108.00
        case .septicTank: return nil
        }
    }

    /// Refundable security bond on top of the application fee, where one applies - excluded
    /// from cost totals since it's returned, just surfaced as a note.
    var refundableBond: Double? {
        switch self {
        case .assetProtection: return 2_060.00
        default: return nil
        }
    }
}
