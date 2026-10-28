//
//  PropertyProfileView.swift
//  GroundTruth
//

import SwiftUI

struct PropertyProfileView: View {
    let address: String
    let planningInfo: PropertyPlanningInfo?

    @State private var expandedRowIDs: Set<String> = []

    var body: some View {
        List {
            Section {
                Text(address)
                    .font(.title3)
                    .fontWeight(.semibold)
            }

            Section("Planning Zone") {
                if let zoneName = planningInfo?.zoneName {
                    let category = PlanningStyle.zoneCategory(forZoneCode: planningInfo?.zoneCode)
                    planningRow(
                        id: "zone",
                        name: zoneName,
                        color: category.color,
                        description: category.description
                    )
                } else {
                    Text("No zone data available")
                        .foregroundStyle(.secondary)
                }
            }

            Section("Planning Overlays") {
                let overlayNames = planningInfo?.overlayNames ?? []
                let overlayCodes = planningInfo?.overlayCodes ?? []

                if overlayNames.isEmpty {
                    Text("No overlays on this property")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(Array(overlayNames.enumerated()), id: \.offset) { index, name in
                        let category = PlanningStyle.overlayCategory(forOverlayCode: overlayCodes[index])
                        planningRow(
                            id: "overlay-\(index)",
                            name: name,
                            color: category.color,
                            description: category.description
                        )
                    }
                }
            }
        }
        .navigationTitle("Property")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func planningRow(id: String, name: String, color: Color, description: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Button {
                toggle(id)
            } label: {
                HStack(spacing: 10) {
                    Circle()
                        .fill(color)
                        .frame(width: 12, height: 12)
                    Text(name)
                        .font(.subheadline)
                        .foregroundStyle(.primary)
                    Spacer()
                    Image(systemName: expandedRowIDs.contains(id) ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .buttonStyle(.plain)

            if expandedRowIDs.contains(id) {
                Text(description)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .padding(.leading, 22)
            }
        }
        .padding(.vertical, 4)
    }

    private func toggle(_ id: String) {
        if expandedRowIDs.contains(id) {
            expandedRowIDs.remove(id)
        } else {
            expandedRowIDs.insert(id)
        }
    }
}

#Preview {
    NavigationStack {
        PropertyProfileView(
            address: "1 Collins St, Melbourne",
            planningInfo: PropertyPlanningInfo(
                zoneName: "General Residential Zone - Schedule 1",
                zoneCode: "GRZ1",
                overlayNames: ["Heritage Overlay - Schedule 123"],
                overlayCodes: ["HO123"]
            )
        )
    }
}
