//
//  UserProfile.swift
//  GroundTruth
//
//  Created by Aryan Cyrus  on 15/9/2026.
//

import Foundation
import FirebaseFirestore

struct UserProfile: Identifiable{
    let id: String
    let displayName: String
    let email: String
    
    var creationData: [String: Any] {
        [
            "displayName": displayName,
            "email": email,
            "createdAt": FieldValue.serverTimestamp()
        ]
    }
}
