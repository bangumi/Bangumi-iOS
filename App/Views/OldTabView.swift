import CoreSpotlight
import SwiftUI

struct OldTabView: View {
  @AppStorage("isAuthenticated") var isAuthenticated: Bool = false
  @AppStorage("isolationMode") var isolationMode: Bool = false
  @AppStorage("mainTab") var mainTab: ChiiViewTab = .timeline

  @State private var timelineNav: NavigationPath = NavigationPath()
  @State private var progressNav: NavigationPath = NavigationPath()
  @State private var discoverNav: NavigationPath = NavigationPath()
  @State private var rakuenNav: NavigationPath = NavigationPath()
  @State private var meNav: NavigationPath = NavigationPath()

  private func selectVisibleTabIfNeeded() {
    if !isAuthenticated, mainTab == .progress || mainTab == .me {
      mainTab = .timeline
    }
    if isolationMode, mainTab == .rakuen {
      mainTab = .timeline
    }
  }

  var body: some View {
    TabView(selection: $mainTab) {
      NavigationStack(path: $timelineNav) {
        ChiiTimelineView()
          .navigationDestination(for: NavDestination.self) { $0 }
      }
      .tag(ChiiViewTab.timeline)
      .tabItem {
        Label(ChiiViewTab.timeline.title, systemImage: ChiiViewTab.timeline.icon)
      }
      .environment(
        \.openURL,
        OpenURLAction { url in
          if handleURL(url, nav: $timelineNav) {
            return .handled
          } else {
            return .systemAction
          }
        }
      )

      if isAuthenticated {
        NavigationStack(path: $progressNav) {
          ChiiProgressView()
            .navigationDestination(for: NavDestination.self) { $0 }
        }
        .tag(ChiiViewTab.progress)
        .tabItem {
          Label(ChiiViewTab.progress.title, systemImage: ChiiViewTab.progress.icon)
        }
        .environment(
          \.openURL,
          OpenURLAction { url in
            if handleURL(url, nav: $progressNav) {
              return .handled
            } else {
              return .systemAction
            }
          }
        )
      }

      if isAuthenticated {
        NavigationStack(path: $meNav) {
          CollectionsView()
            .navigationDestination(for: NavDestination.self) { $0 }
        }
        .tag(ChiiViewTab.me)
        .tabItem {
          Label(ChiiViewTab.me.title, systemImage: ChiiViewTab.me.icon)
        }
        .environment(
          \.openURL,
          OpenURLAction { url in
            if handleURL(url, nav: $meNav) {
              return .handled
            } else {
              return .systemAction
            }
          }
        )
      }

      if !isolationMode {
        NavigationStack(path: $rakuenNav) {
          ChiiRakuenView()
            .navigationDestination(for: NavDestination.self) { $0 }
        }
        .tag(ChiiViewTab.rakuen)
        .tabItem {
          Label(ChiiViewTab.rakuen.title, systemImage: ChiiViewTab.rakuen.icon)
        }
        .environment(
          \.openURL,
          OpenURLAction { url in
            if handleURL(url, nav: $rakuenNav) {
              return .handled
            } else {
              return .systemAction
            }
          }
        )
      }

      NavigationStack(path: $discoverNav) {
        ChiiDiscoverView()
      }
      .tag(ChiiViewTab.discover)
      .tabItem {
        Label(ChiiViewTab.discover.title, systemImage: ChiiViewTab.discover.icon)
      }
      .environment(
        \.openURL,
        OpenURLAction { url in
          if handleURL(url, nav: $discoverNav) {
            return .handled
          } else {
            return .systemAction
          }
        }
      )
      .onContinueUserActivity(CSSearchableItemActionType) { activity in
        handleSearchActivity(activity, nav: $discoverNav)
        mainTab = .discover
      }
    }
    .onAppear {
      selectVisibleTabIfNeeded()
    }
    .onChange(of: isAuthenticated) { _, _ in
      selectVisibleTabIfNeeded()
    }
    .onChange(of: isolationMode) { _, _ in
      selectVisibleTabIfNeeded()
    }
  }
}
