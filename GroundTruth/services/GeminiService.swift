//
//  GeminiService.swift
//  GroundTruth
//
//  Created by Aryan Cyrus  on 25/9/2026.
//

import Foundation
import FirebaseAILogic


import Foundation
import FirebaseAILogic

class GeminiService {
    private let model: GenerativeModel

    init() {
        let ai = FirebaseAI.firebaseAI(backend: .googleAI())
        model = ai.generativeModel(modelName: "gemini-3.1-flash-lite") // verify this name
    }

    func getModelResponse(prompt: String) async throws -> String {
        let response = try await model.generateContent(prompt)
        return response.text ?? ""
    }
}



