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

/// The AI's classification result for one project's planning permit, cached on the project
/// (see `Project.planningPermitClassification`) so the same project gets one stable answer
/// instead of being re-judged - and potentially re-answered differently - every time it's
/// viewed. Recomputed only when the project's scope changes (`CostEstimateInputSheet`) or the
/// user explicitly asks for a refresh.
struct PlanningPermitClassification: Codable, Hashable {
    enum Requirement: String, Codable {
        case yes, no, uncertain
    }

    var requirement: Requirement
    /// nil when `requirement == .no` - no permit needed means no fee class applies.
    var feeClass: PlanningPermitFeeClass?
    var reasoning: String
    var classifiedAt: Date
}
