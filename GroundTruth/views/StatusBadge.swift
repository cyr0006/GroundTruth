//
//  StatusBadge.swift
//  GroundTruth
//
//  Small shared component used to display a Project's status.
//

import SwiftUI

struct StatusBadge: View {
    let status: ProjectStatus

    private var color: Color {
        switch status {
        case .planning: return .blue
        case .permits: return .orange
        case .construction: return .purple
        case .complete: return .green
        }
    }

    var body: some View {
        Text(status.rawValue)
            .font(.caption2)
            .fontWeight(.semibold)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(color.opacity(0.15), in: Capsule())
            .foregroundStyle(color)
    }
}

#Preview {
    StatusBadge(status: .permits)
}
