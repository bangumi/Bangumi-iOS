//
//  ContentView.swift
//  Chobits
//
//  Created by Chuan Chuan on 2024/4/19.
//

import SwiftData
import SwiftUI

struct ContentView: View {
  @EnvironmentObject var errorHandling: ErrorHandling
  @EnvironmentObject var chiiClient: ChiiClient
  @Environment(\.modelContext) private var modelContext

  @StateObject var navState = NavState()

  private func createTabViewBinding() -> Binding<ContentViewTab> {
    Binding<ContentViewTab>(
      get: { self.navState.selected },
      set: { selectedTab in
        if selectedTab != self.navState.selected {
          self.navState.selected = selectedTab
          return
        }
        switch selectedTab {
        case .timeline:
          self.navState.timelineNavigation.removeLast(self.navState.timelineNavigation.count)
        case .progress:
          self.navState.progressNavigation.removeLast(self.navState.progressNavigation.count)
        case .discover:
          self.navState.discoverNavigation.removeLast(self.navState.discoverNavigation.count)
        }
      }
    )
  }

  var body: some View {
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
    .onAppear {
      Task.detached {
        _ = try await chiiClient.getProfile()
      }
    }
    .environment(chiiClient)
    .environment(navState)
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
