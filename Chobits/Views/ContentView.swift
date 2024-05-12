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
  @State private var selectedTab: ContentViewTab
  @StateObject var navState = NavState()

  init() {
    let defaultTab = UserDefaults.standard.string(forKey: "defaultTab") ?? "discover"
    self.selectedTab = ContentViewTab(defaultTab)
  }

  private func createTabViewBinding() -> Binding<ContentViewTab> {
    Binding<ContentViewTab>(
      get: { self.selectedTab },
      set: { selectedTab in
        if selectedTab != self.selectedTab {
          self.selectedTab = selectedTab
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
        await chii.setAuthStatus(true)
        self.initialized = true
        return
      } catch ChiiError.requireLogin {
        await chii.setAuthStatus(false)
        self.initialized = true
        return
      } catch {
        Logger.api.warning("refresh profile failed: \(error)")
      }
    }
    await chii.setAuthStatus(false)
    self.initialized = true
  }

  var body: some View {
    if !initialized {
      VStack {
        LoadingView().onAppear {
          Task {
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
      }
      .environment(navState)
    }
  }
}

class NavState: ObservableObject, Observable {
  @Published var timelineNavigation: [NavDestination] = []
  @Published var progressNavigation: [NavDestination] = []
  @Published var discoverNavigation: [NavDestination] = []
}
