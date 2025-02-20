import CoreSpotlight
import OSLog
import SwiftUI

@available(iOS 18.0, *)
struct PadView: View {
  @AppStorage("isAuthenticated") var isAuthenticated: Bool = false
  @AppStorage("isolationMode") var isolationMode: Bool = false

  @State private var selectedTab: ChiiViewTab

  @State private var timelineNav: NavigationPath = NavigationPath()
  @State private var progressNav: NavigationPath = NavigationPath()
  @State private var discoverNav: NavigationPath = NavigationPath()
  @State private var rakuenNav: NavigationPath = NavigationPath()

  @State private var searchQuery: String = ""
  @State private var searching: Bool = false

  @State private var profile: SlimUserDTO?

  init() {
    let defaultTab = UserDefaults.standard.string(forKey: "defaultTab") ?? ""
    self.selectedTab = ChiiViewTab(defaultTab)
  }

  var body: some View {
    TabView(selection: $selectedTab) {
      Tab(ChiiViewTab.timeline.title, systemImage: ChiiViewTab.timeline.icon, value: .timeline) {
        NavigationStack(path: $timelineNav) {
          ChiiTimelineView()
            .navigationDestination(for: NavDestination.self) { $0 }
        }.environment(
          \.openURL,
          OpenURLAction { url in
            if handleChiiURL(url, nav: $timelineNav) {
              return .handled
            } else {
              return .systemAction
            }
          }
        )
      }

      if isAuthenticated {
        Tab(ChiiViewTab.progress.title, systemImage: ChiiViewTab.progress.icon, value: .progress) {
          NavigationStack(path: $progressNav) {
            ChiiProgressView()
              .navigationDestination(for: NavDestination.self) { $0 }
          }.environment(
            \.openURL,
            OpenURLAction { url in
              if handleChiiURL(url, nav: $progressNav) {
                return .handled
              } else {
                return .systemAction
              }
            }
          )
        }
      }

      Tab(ChiiViewTab.discover.title, systemImage: ChiiViewTab.discover.icon, value: .discover) {
        NavigationStack(path: $discoverNav) {
          Section {
            if searching {
              SearchView(text: $searchQuery, searching: $searching)
            } else {
              ChiiDiscoverView()
            }
          }.navigationDestination(for: NavDestination.self) { $0 }
        }
        .searchable(text: $searchQuery, isPresented: $searching, placement: .toolbar)
        .environment(
          \.openURL,
          OpenURLAction { url in
            if handleChiiURL(url, nav: $discoverNav) {
              return .handled
            } else {
              return .systemAction
            }
          }
        )
        .onContinueUserActivity(CSSearchableItemActionType) { activity in
          handleSearchActivity(activity, nav: $discoverNav)
          selectedTab = .discover
        }
      }

      if !isolationMode {
        Tab(ChiiViewTab.rakuen.title, systemImage: ChiiViewTab.rakuen.icon, value: .rakuen) {
          NavigationStack(path: $rakuenNav) {
            ChiiRakuenView()
              .navigationDestination(for: NavDestination.self) { $0 }
          }.environment(
            \.openURL,
            OpenURLAction { url in
              if handleChiiURL(url, nav: $rakuenNav) {
                return .handled
              } else {
                return .systemAction
              }
            }
          )
        }
      }
    }
  }
}
