//
//  CostEstimatorService.swift
//  GroundTruth
//
//  Created by Aryan Cyrus  on 28/10/2026.
//

import Foundation
import CoreML

enum CostEstimateResult{
    case available (low: Double, high: Double)
    case ruleOfThumb(low: Double, high: Double, note: String)
    /// This project doesn't need this line item at all (e.g. no planning permit expected).
    case notApplicable
    case unavailable
}

/// One council-approval checklist row, paired with its computed cost state.
struct CouncilApprovalLineItem: Identifiable {
    var type: CouncilApprovalType
    var result: CostEstimateResult
    var id: String { type.rawValue }
}

/// The cost line items shown to the user, rather than one blended number - each can
/// independently be a real estimate, a rule of thumb, not applicable, or simply unknown.
/// `complianceAssessment` is carried through so the UI can show the AI's likelihood tier and
/// reasoning alongside each row, not just the resulting dollar figure.
struct CostBreakdown {
    var construction: CostEstimateResult
    var buildingPermit: CostEstimateResult
    var planningPermit: CostEstimateResult
    var councilApprovals: [CouncilApprovalLineItem]
    /// nil means "not yet assessed for the current scope" - distinct from the project having
    /// no scope at all, which each line item already represents as `.unavailable`.
    var complianceAssessment: ProjectComplianceAssessment?
}

final class CostEstimatorService {
    private let model: CostEstimator?

    init() {
        model = try? CostEstimator(configuration: MLModelConfiguration())
    }

    func estimate(for inputs: CostEstimateInputs?) -> CostEstimateResult{
        guard let inputs else {return .unavailable}

        if inputs.projectType == ProjectType.boundaryCivilWorks.rawValue {
            return estimateBoundaryCivilWorks(subtype: inputs.workSubtype)
        }

        guard let model else {return .unavailable}
        guard let prediction = try? model.prediction(
            floorAreaSqm: inputs.floorAreaSqm, projectType: inputs.projectType
        )  else {return .unavailable}

        //We use exp as model was trained on ln(costOfWorks), NOT raw dollars. Exp undones/calculates dollar value
        let point = exp(prediction.logCost)
        guard point.isFinite, point>0, point<10_000_000 else {return .unavailable}

        // Use of flat +-30%  to account for HIGH model error/RMSE; TODO FIX LATER FOR BETTER ACCURACY
        return .available(low: max(0, point * 0.7), high: point * 1.3)
    }

    /// The full breakdown: construction (the model, same as `estimate(for:)`), building permit
    /// (gated by the AI's likelihood tier, fee via formula off construction cost), planning
    /// permit (gated by likelihood, fee looked up from `PlanningPermitFeeClass` - real
    /// statutory $ amounts, never AI-stated or model-predicted), and one line per council
    /// approval (gated by likelihood, fee from `CouncilApprovalType`). All three
    /// permit/approval judgments come from `project.complianceAssessment`, cached from the
    /// last `ProjectComplianceClassifierService` run - this service has no network access and
    /// makes no AI call itself.
    func breakdown(for project: Project) -> CostBreakdown {
        let construction = estimate(for: project.costEstimateInputs)
        let assessment = project.complianceAssessment
        let hasScope = project.costEstimateInputs != nil

        return CostBreakdown(
            construction: construction,
            buildingPermit: buildingPermitResult(for: construction, assessment: assessment?.buildingPermit, hasScope: hasScope),
            planningPermit: planningPermitResult(for: assessment?.planningPermit, hasScope: hasScope),
            councilApprovals: councilApprovalResults(for: assessment?.councilApprovals, hasScope: hasScope),
            complianceAssessment: assessment
        )
    }

    // Building surveyor fees for issuing a building permit are a small, fairly standard
    // percentage of cost-of-works, unlike the cost-of-works figure itself - a formula, not
    // something the model needs to predict separately. Still gated by the AI's likelihood,
    // since not every project actually needs a building permit at all.
    private func buildingPermitResult(for construction: CostEstimateResult, assessment: BuildingPermitAssessment?, hasScope: Bool) -> CostEstimateResult {
        guard hasScope else { return .unavailable }
        guard let assessment else { return .unavailable }
        guard assessment.likelihood.impliesCostApplies else { return .notApplicable }

        switch construction {
        case .available(let low, let high), .ruleOfThumb(let low, let high, _):
            return .ruleOfThumb(
                low: buildingSurveyorFee(forCostOfWorks: low),
                high: buildingSurveyorFee(forCostOfWorks: high),
                note: "\(assessment.likelihood.displayLabel). Approx. building surveyor fee (~0.75% of cost of works). \(assessment.reasoning)"
            )
        case .notApplicable, .unavailable:
            return .unavailable
        }
    }

    private func buildingSurveyorFee(forCostOfWorks cost: Double) -> Double {
        max(220, cost * 0.0075)
    }

    // Reads whatever ProjectComplianceClassifierService last decided for this project (cached
    // on the project document, not recomputed here). nil assessment means "not assessed yet
    // for the current scope," which the UI prompts the user to trigger.
    private func planningPermitResult(for assessment: PlanningPermitAssessment?, hasScope: Bool) -> CostEstimateResult {
        guard hasScope else { return .unavailable }
        guard let assessment else { return .unavailable }
        guard assessment.likelihood.impliesCostApplies else { return .notApplicable }
        guard let feeClass = assessment.feeClass else { return .unavailable }

        return .ruleOfThumb(
            low: feeClass.fee, high: feeClass.fee,
            note: "\(assessment.likelihood.displayLabel) - \(feeClass.displayName). \(assessment.reasoning)"
        )
    }

    // One line per CouncilApprovalType, always in a fixed order (regardless of what order the
    // AI returned them in, or whether it omitted one) so the UI never looks like it silently
    // dropped a checklist item.
    private func councilApprovalResults(for approvals: [CouncilApprovalAssessment]?, hasScope: Bool) -> [CouncilApprovalLineItem] {
        CouncilApprovalType.allCases.map { type in
            guard hasScope else { return CouncilApprovalLineItem(type: type, result: .unavailable) }
            guard let match = approvals?.first(where: { $0.type == type }) else {
                return CouncilApprovalLineItem(type: type, result: .unavailable)
            }
            guard match.likelihood.impliesCostApplies else {
                return CouncilApprovalLineItem(type: type, result: .notApplicable)
            }
            guard let fee = type.fee else {
                return CouncilApprovalLineItem(type: type, result: .unavailable)
            }

            let bondNote = type.refundableBond.map { " + $\(Int($0)) refundable bond" } ?? ""
            return CouncilApprovalLineItem(
                type: type,
                result: .ruleOfThumb(
                    low: fee, high: fee,
                    note: "\(match.likelihood.displayLabel)\(bondNote). \(match.reasoning)"
                )
            )
        }
    }

    // Boundary & Civil Works (BCA Class 10b) lumps fences in with retaining walls, pools and
    // masts. Ordinary fences almost never trigger a building permit in Victoria, so they're
    // barely represented in the permit data the model is trained on - a floor-area-based
    // prediction for "fence" actually reflects the pool/retaining-wall population, not a fence.
    // Fences get a flat rule of thumb instead; retaining wall/pool are closer to what the 10b
    // data actually represents, so they still use the model (floor area carries no signal for
    // this category, so it's passed as 0 - matches how the training data was prepared).
    private func estimateBoundaryCivilWorks(subtype: String?) -> CostEstimateResult {
        switch subtype {
        case BoundaryWorkSubtype.fence.rawValue:
            return .ruleOfThumb(
                low: 3_000, high: 15_000,
                note: "Typical residential boundary fence - rule of thumb, not model-based. Recalibrate against local trade rates."
            )
        case BoundaryWorkSubtype.retainingWall.rawValue, BoundaryWorkSubtype.pool.rawValue:
            guard let model else { return .unavailable }
            guard let prediction = try? model.prediction(
                floorAreaSqm: 0, projectType: ProjectType.boundaryCivilWorks.rawValue
            ) else { return .unavailable }
            let point = exp(prediction.logCost)
            guard point.isFinite, point > 0, point < 10_000_000 else { return .unavailable }
            return .ruleOfThumb(
                low: max(0, point * 0.7), high: point * 1.3,
                note: "Based on a mix of pool and retaining-wall permits - expect a wide range."
            )
        default:
            return .unavailable
        }
    }
}
