//
//  AccentColorStore.swift
//  GroundTruth
//
//  Created by Aryan Cyrus  on 1/11/2026.
//

import SwiftUI
import UIKit

/// Stores the user's chosen accent (tint) colour. Deliberately does not touch light/dark
/// mode, which stays under the device's own Display & Brightness setting per Apple's HIG.
enum AccentColorStore {
    static let storageKey = "accentColorHex"
    /// Matches SwiftUI's system default tint, so an unset preference looks unchanged.
    static let defaultHex = "#007AFFFF"
}

extension Color {
    init?(hex: String) {
        let hexString = hex.trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "#", with: "")
        guard hexString.count == 8, let value = UInt64(hexString, radix: 16) else { return nil }

        self = Color(
            .sRGB,
            red: Double((value >> 24) & 0xFF) / 255,
            green: Double((value >> 16) & 0xFF) / 255,
            blue: Double((value >> 8) & 0xFF) / 255,
            opacity: Double(value & 0xFF) / 255
        )
    }

    var hexString: String {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        UIColor(self).getRed(&r, green: &g, blue: &b, alpha: &a)
        return String(format: "#%02X%02X%02X%02X", Int(r * 255), Int(g * 255), Int(b * 255), Int(a * 255))
    }
}
