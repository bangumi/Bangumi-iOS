//
//  ContentView.swift
//  Bangumi
//
//  Created by Chuan Chuan on 2024/4/19.
//

import SwiftData
import SwiftUI

enum Tab: String, CaseIterable, Identifiable {
    case home
    case progress
    case discover

    var id: Self { self }
}

struct ContentView: View {
    @State private var tab = Tab.progress

    var body: some View {
        TabView(selection: $tab) {
            HomeView()
                .tabItem {
                    Label("Home", systemImage: "person")
                }.tag(Tab.home)
            ProgressView()
                .tabItem {
                    Label("Progress", systemImage: "square.grid.3x2.fill")
                }.tag(Tab.progress)
            DiscoverView()
                .tabItem {
                    Label("Discover", systemImage: "magnifyingglass")
                }.tag(Tab.discover)
        }
    }
}

#Preview {
    ContentView()
}
