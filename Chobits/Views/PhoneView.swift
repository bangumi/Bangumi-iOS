//
//  PhoneView.swift
//  Chobits
//
//  Created by Chuan Chuan on 2024/10/29.
//

import CoreSpotlight
import SwiftUI

struct PhoneView: View {
  @AppStorage("isAuthenticated") var isAuthenticated: Bool = false

  @State private var selectedTab: PhoneViewTab
  @State private var nav: NavigationPath = NavigationPath()

  init() {
    let defaultTab = UserDefaults.standard.string(forKey: "defaultTab") ?? "discover"
    self.selectedTab = PhoneViewTab(defaultTab)
  }

  var body: some View {
    TabView(selection: $selectedTab) {

      NavigationStack {
        ChiiTimelineView()
          .navigationBarTitleDisplayMode(.inline)
          .navigationDestination(for: NavDestination.self) { $0 }
      }
      .tag(PhoneViewTab.timeline)
      .tabItem {
        Label(PhoneViewTab.timeline.title, systemImage: PhoneViewTab.timeline.icon)
      }

      if isAuthenticated {
        NavigationStack {
          ChiiProgressView()
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(for: NavDestination.self) { $0 }
        }
        .tag(PhoneViewTab.progress)
        .tabItem {
          Label(PhoneViewTab.progress.title, systemImage: PhoneViewTab.progress.icon)
        }
      }

      NavigationStack {
        CalendarView()
          .navigationBarTitleDisplayMode(.inline)
          .navigationDestination(for: NavDestination.self) { $0 }
      }
      .tag(PhoneViewTab.discover)
      .tabItem {
        Label(PhoneViewTab.discover.title, systemImage: PhoneViewTab.discover.icon)
      }

      NavigationStack(path: $nav) {
        SearchView()
          .navigationBarTitleDisplayMode(.inline)
          .navigationDestination(for: NavDestination.self) { $0 }
      }
      .tag(PhoneViewTab.search)
      .tabItem {
        Label(PhoneViewTab.search.title, systemImage: PhoneViewTab.search.icon)
      }
      .onContinueUserActivity(CSSearchableItemActionType) { activity in
        handleSearchActivity(activity, nav: $nav)
        selectedTab = .search
      }
    }
  }
}
