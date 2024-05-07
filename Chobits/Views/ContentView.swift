//
//  ContentView.swift
//  Chobits
//
//  Created by Chuan Chuan on 2024/4/19.
//

import OSLog
import SwiftData
import SwiftUI

struct ContentView: View {
  @EnvironmentObject var notifier: Notifier
  @EnvironmentObject var chii: ChiiClient

  @State private var initialized = false
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
          self.navState.timelineNavigation.removeAll()
        case .progress:
          self.navState.progressNavigation.removeAll()
        case .discover:
          self.navState.discoverNavigation.removeAll()
        }
      }
    )
  }

  func refreshProfile() async {
    var tries = 0
    while true {
      if tries > 3 {
        break
      }
      tries += 1
      do {
        _ = try await chii.getProfile()
        chii.isAuthenticated = true
        self.initialized = true
        return
      } catch ChiiError.requireLogin {
        chii.isAuthenticated = false
        self.initialized = true
        return
      } catch {
        Logger.api.warning("refresh profile failed: \(error)")
      }
    }
    chii.isAuthenticated = false
    self.initialized = true
  }

  var body: some View {
    if !initialized {
      VStack {
        LoadingView().onAppear {
          Task{
            await refreshProfile()
          }
        }
      }
    } else {
      TabView(selection: createTabViewBinding()) {
        ChiiTimelineView()
          .tag(ContentViewTab.timeline)
          .tabItem {
            Image(systemName: "person")
          }
        ChiiProgressView()
          .tag(ContentViewTab.progress)
          .tabItem {
            Image(systemName: "square.grid.3x2.fill")
          }
        ChiiDiscoverView()
          .tag(ContentViewTab.discover)
          .tabItem {
            Image(systemName: "magnifyingglass")
          }
      }.environment(navState)
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
  @Published var timelineNavigation: [NavDestination] = []
  @Published var progressNavigation: [NavDestination] = []
  @Published var discoverNavigation: [NavDestination] = []
}
