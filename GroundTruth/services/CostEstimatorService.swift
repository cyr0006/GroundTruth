//
//  CostEstimatorService.swift
//  GroundTruth
//
//  Created by Aryan Cyrus  on 28/10/2026.
//

import Foundation
import CoreML

enum CostEstamateResult{
    case available (low: Double, high: Double)
    case unavailable
}

final class CostEstimatorService {
    private let model: CostEstimator?
    
    init() {
        model = try? CostEstimator(configuration: MLModelConfiguration())
    }
    
    func estimate(for inputs: CostEstimateInputs?) -> CostEstamateResult{
        guard let inputs, let model else {return .unavailable}
        guard let prediction = try? model.prediction(
            floorAreaSqm: inputs.floorAreaSqm, projectType: inputs.projectType
        )  else {return .unavailable}
        
        //We use exp as model was trained on ln(costOfWorks), NOT raw dollars. Exp undones/calculates dollar value
        let point = exp(prediction.logCost)
        guard point.isFinite, point>0, point<10_000_000 else {return .unavailable}
        
        // Use of flat +-30%  to account for HIGH model error/RMSE; TODO FIX LATER FOR BETTER ACCURACY
        return .available(low: max(0, point * 0.7), high: point * 1.3)
    }
}
