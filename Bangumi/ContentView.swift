//
//  ContentView.swift
//  Bangumi
//
//  Created by Chuan Chuan on 2024/4/19.
//

import SwiftData
import SwiftUI

enum Tab: String, CaseIterable, Identifiable {
    case timeline
    case progress
    case discover

    var id: Self { self }
}

struct ContentView: View {
    @State private var tab = Tab.progress
    @Query private var auths: [Auth]
    @Query private var profiles: [Profile]

    private var auth: Auth? { auths.first }
    private var profile: Profile? { profiles.first }

    var body: some View {
        switch auth {
        case .some:
            TabView(selection: $tab) {
                TimelineView()
                    .tabItem {
                        Label("Timeline", systemImage: "person")
                    }.tag(Tab.timeline)
                ProgressView()
                    .tabItem {
                        Label("Progress", systemImage: "square.grid.3x2.fill")
                    }.tag(Tab.progress)
                DiscoverView()
                    .tabItem {
                        Label("Discover", systemImage: "magnifyingglass")
                    }.tag(Tab.discover)
            }
        case .none:
            AuthView()
        }
    }
}

#Preview {
    ContentView()
}
