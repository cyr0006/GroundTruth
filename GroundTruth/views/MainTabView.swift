//
//  MainTabView.swift
//  GroundTruth
//
//  Created by Aryan Cyrus  on 15/9/2026.
//

import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
            HomeView()
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }

            MapView()
                .tabItem {
                    Label("Map", systemImage: "map.fill")
                }

            ProjectsView()
                .tabItem {
                    Label("Projects", systemImage: "hammer.fill")
                }

            FAQView()
                .tabItem {
                    Label("FAQ", systemImage: "questionmark.circle.fill")
                }

            ProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person.crop.circle.fill")
                }
        }
    }
}

#Preview {
    MainTabView()
        .environmentObject(ProjectStore())
}
