//
//  ContentView.swift
//  Bangumi
//
//  Created by Chuan Chuan on 2024/4/19.
//

import SwiftData
import SwiftUI

struct ContentView: View {
  @EnvironmentObject var errorHandling: ErrorHandling
  @Environment(\.modelContext) private var modelContext

  @StateObject var navState = NavState()
  @Query private var auths: [Auth]

  private var auth: Auth? { auths.first }

  private func createTabViewBinding() -> Binding<ContentViewTab> {
    Binding<ContentViewTab>(
      get: { navState.selected },
      set: { selectedTab in
        if selectedTab != navState.selected {
          navState.selected = selectedTab
          return
        }
        switch selectedTab {
        case .timeline:
          withAnimation {
            navState.timelineNavigation.removeLast(navState.timelineNavigation.count)
          }
        case .progress:
          withAnimation {
            navState.progressNavigation.removeLast(navState.progressNavigation.count)
          }
        case .discover:
          withAnimation {
            navState.discoverNavigation.removeLast(navState.discoverNavigation.count)
          }
        }
      }
    )
  }

  var body: some View {
    switch auth {
    case .some(let auth):
      let chiiClient = ChiiClient(errorHandling: errorHandling, modelContext: modelContext, auth: auth)
      TabView(selection: createTabViewBinding()) {
        TimelineView()
          .tag(ContentViewTab.timeline)
          .tabItem {
            Image(systemName: "person")
          }
        ProgressView()
          .tag(ContentViewTab.progress)
          .tabItem {
            Image(systemName: "square.grid.3x2.fill")
          }
        DiscoverView()
          .tag(ContentViewTab.discover)
          .tabItem {
            Image(systemName: "magnifyingglass")
          }
      }
      .environment(chiiClient)
      .environment(navState)
    case .none:
      AuthView()
    }
  }
}

enum ContentViewTab: String, CaseIterable, Identifiable {
  case timeline
  case progress
  case discover

  var id: Self { self }
}

class NavState: ObservableObject, Observable {
  @Published var selected: ContentViewTab = .progress
  @Published var timelineNavigation = NavigationPath()
  @Published var progressNavigation = NavigationPath()
  @Published var discoverNavigation = NavigationPath()
}
