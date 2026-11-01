//
//  ProjectComplianceAssessment.swift
//  GroundTruth
//

import Foundation

/// The AI's planning permit judgment: whether one is likely needed, and if so, which real
/// fee class applies (see `PlanningPermitFeeClass`) - the AI only ever picks a class id,
/// never a dollar figure.
struct PlanningPermitAssessment: Codable, Hashable {
    var likelihood: PermitLikelihood
    /// nil when likelihood doesn't imply a cost applies (see `PermitLikelihood.impliesCostApplies`).
    var feeClass: PlanningPermitFeeClass?
    var reasoning: String
}

/// The AI's building permit judgment - no fee class needed here, since the fee is always a
/// formula off the construction cost estimate (`CostEstimatorService.buildingSurveyorFee`),
/// not a banded table like planning permits.
struct BuildingPermitAssessment: Codable, Hashable {
    var likelihood: PermitLikelihood
    var reasoning: String
}

/// The AI's judgment for one council-approval checklist item (see `CouncilApprovalType`).
struct CouncilApprovalAssessment: Codable, Hashable {
    var type: CouncilApprovalType
    var likelihood: PermitLikelihood
    var reasoning: String
}

/// One combined assessment for a project, covering planning permit, building permit, and
/// every council-approval checklist item in a single cached result - produced by
/// `ProjectComplianceClassifierService` in one Gemini call rather than three separate ones,
/// since they all need the same zone/overlay/planning-scheme grounding assembled first.
/// Cached on `Project.complianceAssessment` so the same project gets one stable answer
/// instead of being re-judged (and potentially re-answered differently) every time it's
/// viewed - recomputed only when scope changes or the user explicitly asks for a refresh.
struct ProjectComplianceAssessment: Codable, Hashable {
    var planningPermit: PlanningPermitAssessment
    var buildingPermit: BuildingPermitAssessment
    /// Always one entry per `CouncilApprovalType` case, in a fixed order.
    var councilApprovals: [CouncilApprovalAssessment]
    var assessedAt: Date
}
