//
//  PlanningPermitFeeSchedule.swift
//  GroundTruth
//

import Foundation

/// Victoria's actual planning permit application fees (Planning and Environment (Fees)
/// Regulations), 2026-27 financial year - fee unit $17.27. These are fixed statutory dollar
/// amounts, not a formula. The fee unit changes every 1 July, so every amount below needs
/// re-verifying against that year's published schedule (e.g. a council's statutory planning
/// fee schedule PDF) when it does - don't assume these stay correct indefinitely.
enum PlanningPermitFeeClass: String, CaseIterable, Codable {
    case vicSmart = "vicsmart"
    case singleDwellingClass2 = "single_dwelling_class2"
    case singleDwellingClass3 = "single_dwelling_class3"
    case singleDwellingClass4 = "single_dwelling_class4"
    case singleDwellingClass5 = "single_dwelling_class5"
    case singleDwellingClass6 = "single_dwelling_class6"
    case otherDevelopmentClass11 = "other_development_class11"
    case otherDevelopmentClass12 = "other_development_class12"
    case subdivisionClass17to19 = "subdivision_class17_19"

    var displayName: String {
        switch self {
        case .vicSmart: return "VicSmart (minor works)"
        case .singleDwellingClass2: return "Single dwelling - up to $10,000"
        case .singleDwellingClass3: return "Single dwelling - $10,001 to $100,000"
        case .singleDwellingClass4: return "Single dwelling - $100,001 to $500,000"
        case .singleDwellingClass5: return "Single dwelling - $500,001 to $1,000,000"
        case .singleDwellingClass6: return "Single dwelling - $1,000,001 to $2,000,000"
        case .otherDevelopmentClass11: return "Other development - $100,000 or less"
        case .otherDevelopmentClass12: return "Other development - $100,001 to $1,000,000"
        case .subdivisionClass17to19: return "Subdivision"
        }
    }

    /// The fixed statutory fee for this class, 2026-27 financial year.
    var fee: Double {
        switch self {
        case .vicSmart: return 233.10
        case .singleDwellingClass2: return 233.10
        case .singleDwellingClass3: return 734.00
        case .singleDwellingClass4: return 1_502.50
        case .singleDwellingClass5: return 1_623.40
        case .singleDwellingClass6: return 1_744.30
        case .otherDevelopmentClass11: return 1_338.40
        case .otherDevelopmentClass12: return 1_804.70
        case .subdivisionClass17to19: return 1_537.00
        }
    }
}

/// Shared 5-tier scale for "is this permit/approval needed," used across planning permit,
/// building permit, and every council-approval checklist item. Deliberately qualitative
/// rather than a numeric probability - a model stating "73% likely" isn't actually more
/// calibrated than "likely," just dressed up to look more precise than it is.
enum PermitLikelihood: String, Codable, CaseIterable {
    case required
    case likelyRequired = "likely_required"
    case possiblyRequired = "possibly_required"
    case unlikelyRequired = "unlikely_required"
    case notRequired = "not_required"

    var displayLabel: String {
        switch self {
        case .required: return "Required"
        case .likelyRequired: return "Likely required"
        case .possiblyRequired: return "Possibly required"
        case .unlikelyRequired: return "Unlikely required"
        case .notRequired: return "Not required"
        }
    }

    /// Whether this tier is worth showing a fee for at all - "unlikely"/"not required" show
    /// as not applicable instead, same treatment as a hard "no".
    var impliesCostApplies: Bool {
        self == .required || self == .likelyRequired || self == .possiblyRequired
    }
}
