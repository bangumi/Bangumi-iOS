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
    @EnvironmentObject var errorHandling: ErrorHandling
    @Environment(\.modelContext) private var modelContext

    @State private var tab = Tab.progress
    @Query private var auths: [Auth]

    private var auth: Auth? { auths.first }

    var body: some View {
        switch auth {
        case .some(let auth):
            let chiiClient = ChiiClient(errorHandling: errorHandling, modelContext: modelContext, auth: auth)
            TabView(selection: $tab) {
                TimelineView()
                    .tag(Tab.timeline)
                    .tabItem {
                        Image(systemName: "person")
                    }
                ProgressView()
                    .tag(Tab.progress)
                    .tabItem {
                        Image(systemName: "square.grid.3x2.fill")
                    }
                DiscoverView()
                    .tag(Tab.discover)
                    .tabItem {
                        Image(systemName: "magnifyingglass")
                    }
            }
            .environment(chiiClient)
        case .none:
            AuthView()
        }
    }
}
