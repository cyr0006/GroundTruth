//
//  AppError.swift
//  GroundTruth
//
//  Created by Aryan Cyrus  on 15/9/2026.
//

import Foundation


import Foundation


enum AppError: LocalizedError {
    case invalidForm(String)
    case projectNotFound
    case notSignedIn
    case complianceAssessmentFailed

    var errorDescription: String? {
        switch self {
        case .invalidForm(let message): message
        case .projectNotFound: "This project no longer exists."
        case .notSignedIn: "You need to be signed in to do that."
        case .complianceAssessmentFailed: "Couldn't assess permits and approvals right now. Try again shortly."
        }
    }
    
    var nsError: NSError {
        NSError(
            domain: "GroundTruthProjects",
            code: 1,
            userInfo: [NSLocalizedDescriptionKey: errorDescription ?? "An unknown error occurred" ]
        )
    }
}
