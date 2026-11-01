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

/// The four cost line items shown to the user, rather than one blended number - each can
/// independently be a real estimate, a rule of thumb, not applicable, or simply unknown.
struct CostBreakdown {
    var construction: CostEstimateResult
    var buildingPermit: CostEstimateResult
    var planningPermit: CostEstimateResult
    /// nil means "not yet classified for the current scope" - distinct from the project
    /// having no scope at all, which `planningPermit` already represents as `.unavailable`.
    var planningPermitClassification: PlanningPermitClassification?
    var council: CostEstimateResult
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

    /// The full four-line breakdown: construction (the model, same as `estimate(for:)`),
    /// building permit fee (a formula off construction cost), planning permit fee (looked up
    /// from `project.planningPermitClassification` - real statutory $ amounts, never AI-stated
    /// or model-predicted), and council fees (currently a placeholder slot - see `councilFees`).
    func breakdown(for project: Project) -> CostBreakdown {
        let construction = estimate(for: project.costEstimateInputs)

        return CostBreakdown(
            construction: construction,
            buildingPermit: buildingPermitFee(for: construction),
            planningPermit: planningPermitResult(for: project),
            planningPermitClassification: project.planningPermitClassification,
            council: councilFees(for: project.costEstimateInputs)
        )
    }

    // Building surveyor fees for issuing a building permit are a small, fairly standard
    // percentage of cost-of-works, unlike the cost-of-works figure itself - a formula, not
    // something the model needs to predict separately.
    private func buildingPermitFee(for construction: CostEstimateResult) -> CostEstimateResult {
        switch construction {
        case .available(let low, let high), .ruleOfThumb(let low, let high, _):
            return .ruleOfThumb(
                low: buildingSurveyorFee(forCostOfWorks: low),
                high: buildingSurveyorFee(forCostOfWorks: high),
                note: "Approximate building surveyor fee (~0.75% of cost of works) - industry rule of thumb, not a quote."
            )
        case .notApplicable, .unavailable:
            return construction
        }
    }

    private func buildingSurveyorFee(forCostOfWorks cost: Double) -> Double {
        max(220, cost * 0.0075)
    }

    // Reads whatever PlanningPermitClassifierService last decided for this project (cached
    // on the project document, not recomputed here - this service has no network access and
    // no business making a fresh AI call on every render). nil classification means "not
    // classified yet for the current scope," which the UI prompts the user to trigger.
    private func planningPermitResult(for project: Project) -> CostEstimateResult {
        guard project.costEstimateInputs != nil else { return .unavailable }
        guard let classification = project.planningPermitClassification else { return .unavailable }

        switch classification.requirement {
        case .no:
            return .notApplicable
        case .yes, .uncertain:
            guard let feeClass = classification.feeClass else { return .unavailable }
            let prefix = classification.requirement == .uncertain ? "Uncertain - " : ""
            return .ruleOfThumb(
                low: feeClass.fee, high: feeClass.fee,
                note: "\(prefix)\(feeClass.displayName). \(classification.reasoning)"
            )
        }
    }

    // TODO: replace with real Cardinia Shire figures (asset protection permit, road/footpath
    // occupation, vehicle crossing, etc. - see the FAQ's "other council permits" entry for what
    // might apply). Returning .unavailable rather than a guessed number until hardcoded for real.
    private func councilFees(for inputs: CostEstimateInputs?) -> CostEstimateResult {
        .unavailable
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
