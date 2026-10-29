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
    case unavailable
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
