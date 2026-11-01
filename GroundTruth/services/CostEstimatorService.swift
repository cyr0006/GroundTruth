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

/// How likely a planning permit is to actually be required, derived from project type
/// alone (not from zone/overlay data, which isn't available synchronously here). Deliberately
/// a 3-state guess rather than a yes/no - genuine applicability depends on planning-scheme
/// detail (setbacks, heights, overlays) this heuristic can't evaluate.
enum PlanningPermitLikelihood: String {
    case notLikely = "Not likely needed"
    case possible = "May be needed"
    case likely = "Likely needed"
}

/// The four cost line items shown to the user, rather than one blended number - each can
/// independently be a real estimate, a rule of thumb, not applicable, or simply unknown.
struct CostBreakdown {
    var construction: CostEstimateResult
    var buildingPermit: CostEstimateResult
    var planningPermit: CostEstimateResult
    var planningPermitLikelihood: PlanningPermitLikelihood
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
    /// building permit fee (a formula off construction cost), planning permit fee + likelihood
    /// (a simplified lookup off project type and estimated cost), and council fees (currently
    /// a placeholder slot - see `councilFees`).
    func breakdown(for inputs: CostEstimateInputs?) -> CostBreakdown {
        let construction = estimate(for: inputs)
        let likelihood = inputs.map(planningPermitLikelihood(for:)) ?? .possible

        return CostBreakdown(
            construction: construction,
            buildingPermit: buildingPermitFee(for: construction),
            planningPermit: planningPermitFee(for: construction, likelihood: likelihood, inputsPresent: inputs != nil),
            planningPermitLikelihood: likelihood,
            council: councilFees(for: inputs)
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

    // Deliberately coarse: real applicability depends on zone/overlay/setback detail this
    // service doesn't have access to (that lives in RegulatoryExerptService, resolved async
    // from the project's address). This is a project-type-only heuristic good enough to flag
    // "don't bother showing a fee" vs "flag that one might be needed" - not a legal answer.
    private func planningPermitLikelihood(for inputs: CostEstimateInputs) -> PlanningPermitLikelihood {
        guard let projectType = ProjectType(rawValue: inputs.projectType) else { return .possible }

        switch projectType {
        case .newBuild:
            return .likely
        case .extensionWork, .outdoorStructure:
            return .possible
        case .renovation:
            return .notLikely
        case .boundaryCivilWorks:
            if let subtype = inputs.workSubtype.flatMap(BoundaryWorkSubtype.init(rawValue:)),
               subtype == .pool || subtype == .retainingWall {
                return .possible
            }
            return .notLikely
        }
    }

    // Victoria's actual planning permit fees are a fixed statutory schedule with ~20 permit
    // classes, each banded by estimated cost of development - a lookup table, not a model.
    // This collapses that to one simplified band so it's honest about being indicative only;
    // which class actually applies (and whether a permit is even required) needs confirming
    // with council regardless.
    private func planningPermitFee(for construction: CostEstimateResult, likelihood: PlanningPermitLikelihood, inputsPresent: Bool) -> CostEstimateResult {
        guard inputsPresent else { return .unavailable }
        guard likelihood != .notLikely else { return .notApplicable }

        let midpoint: Double
        switch construction {
        case .available(let low, let high), .ruleOfThumb(let low, let high, _):
            midpoint = (low + high) / 2
        case .notApplicable, .unavailable:
            midpoint = 0
        }

        let fee: Double
        switch midpoint {
        case ..<10_000: fee = 100
        case ..<100_000: fee = 600
        case ..<500_000: fee = 1_200
        default: fee = 1_500
        }

        return .ruleOfThumb(
            low: fee, high: fee,
            note: "Indicative statutory fee only, simplified from Victoria's real fee schedule - confirm the exact fee, and whether a permit is actually required, with your council."
        )
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
