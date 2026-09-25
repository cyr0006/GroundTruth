//
//  HomeView.swift
//  GroundTruth
//
//  Created by Aryan Cyrus  on 15/9/2026.
//

import SwiftUI
import FirebaseAuth

struct HomeView: View {
    @EnvironmentObject private var projectStore: ProjectStore
    @EnvironmentObject private var authService: AuthService

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    welcomeHeader

                    quickActions

                    activeProjectsSection

                    tipOfTheDay
                }
                .padding()
            }
            .navigationTitle("GroundTruth")
            .background(Color(.systemGroupedBackground))
        }
    }

    //Sections
    private var welcomeHeader: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Welcome back, \(userName)")
                .font(.title2)
                .fontWeight(.bold)
            Text("Here's the latest on your current projects.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    private var quickActions: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick Actions")
                .font(.headline)

            HStack(spacing: 12) {
                QuickActionButton(title: "New Project", systemImage: "plus.circle.fill", tint: .blue)
                QuickActionButton(title: "Search Address", systemImage: "mappin.and.ellipse", tint: .green)
                QuickActionButton(title: "Ask AI", systemImage: "sparkles", tint: .purple)
            }
        }
    }

    private var activeProjectsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Your Projects")
                    .font(.headline)
                Spacer()
                NavigationLink("See all") {
                    ProjectsView()
                }
                .font(.subheadline)
            }

            if projectStore.projects.isEmpty {
                Text("You haven't created a project yet. Tap the Projects tab to add one.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(projectStore.projects) { project in
                            ProjectSummaryCard(project: project)
                        }
                    }
                }
            }
        }
    }

    private var tipOfTheDay: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Did you know?", systemImage: "lightbulb.fill")
                .font(.headline)
                .foregroundStyle(.orange)
            Text("Properties with a Heritage Overlay may need planning approval even for minor exterior changes. Check your property on the Map tab.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.orange.opacity(0.1), in: RoundedRectangle(cornerRadius: 16))
    }
    
    private var userName: String {
        authService.user?.displayName ?? "User"
    }
}

// Subviews

private struct QuickActionButton: View {
    let title: String
    let systemImage: String
    let tint: Color

    var body: some View {
        Button {
            // Some Placeholder action
        } label: {
            VStack(spacing: 8) {
                Image(systemName: systemImage)
                    .font(.title2)
                    .foregroundStyle(tint)
                Text(title)
                    .font(.caption)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.primary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 14))
        }
    }
}

private struct ProjectSummaryCard: View {
    let project: Project

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(project.name)
                .font(.subheadline)
                .fontWeight(.semibold)
                .lineLimit(1)

            Text(project.address)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(2)

            StatusBadge(status: project.status)

            ProgressView(value: project.progress)
                .tint(.accentColor)

            Text("\(project.tasksCompleted)/\(project.totalTasks) tasks complete")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .padding()
        .frame(width: 200, alignment: .leading)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 14))
    }
}

#Preview {
    HomeView()
        .environmentObject(ProjectStore())
}
