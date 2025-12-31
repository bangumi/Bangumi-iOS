import CoreSpotlight
import SwiftUI

@available(iOS 18.0, *)
struct MainView: View {
  @AppStorage("isAuthenticated") var isAuthenticated: Bool = false
  @AppStorage("isolationMode") var isolationMode: Bool = false
  @AppStorage("mainTab") var mainTab: ChiiViewTab = .timeline

  @State private var timelineNav: NavigationPath = NavigationPath()
  @State private var progressNav: NavigationPath = NavigationPath()
  @State private var rakuenNav: NavigationPath = NavigationPath()
  @State private var settingsNav: NavigationPath = NavigationPath()
  @State private var discoverNav: NavigationPath = NavigationPath()

  var body: some View {
    TabView(selection: $mainTab) {
      Tab(ChiiViewTab.timeline.title, systemImage: ChiiViewTab.timeline.icon, value: .timeline) {
        ZoomTransitionContainer {
          NavigationStack(path: $timelineNav) {
            ChiiTimelineView()
              .navigationDestination(for: NavDestination.self) { $0 }
          }
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
      }

      if isAuthenticated {
        Tab(ChiiViewTab.progress.title, systemImage: ChiiViewTab.progress.icon, value: .progress) {
          ZoomTransitionContainer {
            NavigationStack(path: $progressNav) {
              ChiiProgressView()
                .navigationDestination(for: NavDestination.self) { $0 }
            }
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
      }

      if !isolationMode {
        Tab(ChiiViewTab.rakuen.title, systemImage: ChiiViewTab.rakuen.icon, value: .rakuen) {
          ZoomTransitionContainer {
            NavigationStack(path: $rakuenNav) {
              ChiiRakuenView()
                .navigationDestination(for: NavDestination.self) { $0 }
            }
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
      }

      Tab(ChiiViewTab.settings.title, systemImage: ChiiViewTab.settings.icon, value: .settings) {
        NavigationStack(path: $settingsNav) {
          SettingsView()
        }
      }

      Tab(
        ChiiViewTab.discover.title, systemImage: ChiiViewTab.discover.icon,
        value: ChiiViewTab.discover, role: .search
      ) {
        ZoomTransitionContainer {
          NavigationStack(path: $discoverNav) {
            ChiiDiscoverView()
              .navigationDestination(for: NavDestination.self) { $0 }
          }
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

    }.tabBarMinimizeBehaviorIfAvailable()

  }
}
