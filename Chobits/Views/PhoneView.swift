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
    let defaultTab = UserDefaults.standard.string(forKey: "defaultTab") ?? "discover"
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
      .onOpenURL { url in
        handleChiiURL(url, nav: $timelineNav)
      }

      if isAuthenticated {
        NavigationStack(path: $progressNav) {
          ChiiProgressView()
            .navigationDestination(for: NavDestination.self) { $0 }
        }
        .tag(ChiiViewTab.progress)
        .tabItem {
          Label(ChiiViewTab.progress.title, systemImage: ChiiViewTab.progress.icon)
        }
        .onOpenURL { url in
          handleChiiURL(url, nav: $progressNav)
        }
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
        .onOpenURL { url in
          handleChiiURL(url, nav: $discoverNav)
        }
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
