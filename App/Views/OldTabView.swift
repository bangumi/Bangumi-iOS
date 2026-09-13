import CoreSpotlight
import SwiftUI

struct OldTabView: View {
  @AppStorage("isAuthenticated") var isAuthenticated: Bool = false
  @AppStorage("isolationMode") var isolationMode: Bool = false

  @State private var mainTab: ChiiViewTab

  init() {
    _mainTab = State(initialValue: AppConfig.mainTab.startupTab)
  }

  @State private var timelineNav: NavigationPath = NavigationPath()
  @State private var progressNav: NavigationPath = NavigationPath()
  @State private var discoverNav: NavigationPath = NavigationPath()
  @State private var rakuenNav: NavigationPath = NavigationPath()
  @State private var searchNav: NavigationPath = NavigationPath()

  private func selectVisibleTabIfNeeded() {
    if !isAuthenticated, mainTab == .progress {
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
          .themedScreen()
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
            .themedScreen()
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

      if !isolationMode {
        NavigationStack(path: $rakuenNav) {
          ChiiRakuenView()
            .themedScreen()
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
          .themedScreen()
          .navigationDestination(for: NavDestination.self) { $0 }
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

      NavigationStack(path: $searchNav) {
        ChiiSearchView()
          .themedScreen()
          .navigationDestination(for: NavDestination.self) { $0 }
      }
      .tag(ChiiViewTab.search)
      .tabItem {
        Label(ChiiViewTab.search.title, systemImage: ChiiViewTab.search.icon)
      }
      .environment(
        \.openURL,
        OpenURLAction { url in
          if handleURL(url, nav: $searchNav) {
            return .handled
          } else {
            return .systemAction
          }
        }
      )
      .onContinueUserActivity(CSSearchableItemActionType) { activity in
        handleSearchActivity(activity, nav: $searchNav)
        mainTab = .search
      }
    }
    .onAppear {
      selectVisibleTabIfNeeded()
    }
    .onChange(of: mainTab) { _, newValue in
      AppConfig.mainTab = newValue
    }
    .onChange(of: isAuthenticated) { _, _ in
      selectVisibleTabIfNeeded()
    }
    .onChange(of: isolationMode) { _, _ in
      selectVisibleTabIfNeeded()
    }
  }
}
