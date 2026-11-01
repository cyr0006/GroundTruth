//
//  AppearanceView.swift
//  GroundTruth
//
//  Created by Aryan Cyrus  on 1/11/2026.
//

import SwiftUI

struct AppearanceView: View {
    @AppStorage(AccentColorStore.storageKey) private var accentColorHex = AccentColorStore.defaultHex

    private var accentColorBinding: Binding<Color> {
        Binding(
            get: { Color(hex: accentColorHex) ?? AccentColorStore.defaultColor },
            set: { accentColorHex = $0.hexString }
        )
    }

    var body: some View {
        List {
            Section {
                ColorPicker("Accent Colour", selection: accentColorBinding, supportsOpacity: false)
            } footer: {
                Text("""
                Choose the colour used for buttons and highlights throughout GroundTruth. Light \
                and dark mode still follow your device's own Display & Brightness setting.
                """)
            }

            if accentColorHex != AccentColorStore.defaultHex {
                Section {
                    Button("Reset to Default") {
                        accentColorHex = AccentColorStore.defaultHex
                    }
                }
            }
        }
        .navigationTitle("Appearance")
    }
}

#Preview {
    NavigationStack {
        AppearanceView()
    }
}
