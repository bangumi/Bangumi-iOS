import CoreSpotlight
import SwiftUI

struct PhoneView: View {
  @AppStorage("isAuthenticated") var isAuthenticated: Bool = false

  @State private var selectedTab: ChiiViewTab

  @State private var timelineNav: NavigationPath = NavigationPath()
  @State private var progressNav: NavigationPath = NavigationPath()
  @State private var discoverNav: NavigationPath = NavigationPath()

  @State private var searchQuery: String = ""
  @State private var searchRemote: Bool = false
  @State private var searching: Bool = false

  init() {
    let defaultTab = UserDefaults.standard.string(forKey: "defaultTab") ?? ""
    self.selectedTab = ChiiViewTab(defaultTab)
  }

  var body: some View {
    TabView(selection: $selectedTab) {

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
          if handleChiiURL(url, nav: $timelineNav) {
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
            if handleChiiURL(url, nav: $progressNav) {
              return .handled
            } else {
              return .systemAction
            }
          }
        )
      }

      Section {
        NavigationStack(path: $discoverNav) {
          Section {
            if searching {
              SearchView(text: $searchQuery, remote: $searchRemote)
            } else {
              CalendarView()
            }
          }.navigationDestination(for: NavDestination.self) { $0 }
        }
        .searchable(text: $searchQuery, isPresented: $searching)
        .onSubmit(of: .search) {
          searchRemote = true
        }
        .onChange(of: searchQuery) {
          searchRemote = false
        }
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
      .tag(ChiiViewTab.discover)
      .tabItem {
        Label(ChiiViewTab.discover.title, systemImage: ChiiViewTab.discover.icon)
      }
    }
  }
}
