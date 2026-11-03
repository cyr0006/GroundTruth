//
//  AboutView.swift
//  GroundTruth
//
//  Created by Aryan Cyrus  on 1/11/2026.
//

import SwiftUI

struct AboutView: View {
    @AppStorage(AccentColorStore.storageKey) private var accentColorHex = AccentColorStore.defaultHex

    private var accentColor: Color {
        Color(hex: accentColorHex) ?? AccentColorStore.defaultColor
    }

    // Fixed brand pair from the logo artwork — used only here, on a background this
    // view controls, rather than as a general tint that could clash with the system's.
    private let logoBackground = Color(hex: "#123D36FF") ?? .black
    private let logoForeground = Color(hex: "#F3F0E3FF") ?? .white

    private var appVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    VStack(spacing: 12) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                .fill(logoBackground)
                                .frame(width: 88, height: 88)

                            Image(systemName: "house.and.flag.fill")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 44, height: 44)
                                .foregroundStyle(logoForeground)
                        }

                        Text("GroundTruth")
                            .font(.title2)
                            .fontWeight(.semibold)

                        Text("Your planning and building project companion")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                }
                .listRowBackground(Color.clear)

                Section("What is GroundTruth?") {
                    Text("""
                    Renovating or building a property comes with a lot of rules — zoning, overlays, \
                    permits, costs — scattered across council documents that are hard to read. \
                    GroundTruth brings all of that into one place for a single project.
                    """)
                    .font(.subheadline)
                }

                Section("What it helps you do") {
                    aboutRow(
                        icon: "map",
                        title: "See what's allowed on your site",
                        detail: "Look up your property's zone and planning overlays on a map, pulled from the official Cardinia Planning Scheme."
                    )
                    aboutRow(
                        icon: "bubble.left.and.bubble.right",
                        title: "Ask an AI advisor",
                        detail: "Chat about your project and get answers grounded in the actual planning scheme and building practice notes — not guesses."
                    )
                    aboutRow(
                        icon: "dollarsign.circle",
                        title: "Get a rough cost estimate",
                        detail: "Enter your floor area and project type for a ballpark construction cost."
                    )
                    aboutRow(
                        icon: "checklist",
                        title: "Stay organised",
                        detail: "Track your project through Planning, Permits, Construction and Complete, with notes, tasks and documents all in one spot."
                    )
                }

                Section {
                    Text("""
                    GroundTruth is a guide, not a substitute for council advice — always confirm permit \
                    requirements with your local council before starting work.
                    """)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                }

                Section {
                    LabeledContent("Version", value: appVersion)
                }
            }
            .navigationTitle("About")
        }
    }

    @ViewBuilder
    private func aboutRow(icon: String, title: String, detail: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .frame(width: 24)
                .foregroundStyle(accentColor)
                .padding(.top, 2)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Text(detail)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 2)
    }
}

#Preview {
    AboutView()
}
