import CoreSpotlight
import SwiftUI

struct PhoneView: View {
  @AppStorage("isAuthenticated") var isAuthenticated: Bool = false

  @State private var selectedTab: ChiiViewTab

  @State private var nav: NavigationPath = NavigationPath()
  @State private var searchQuery: String = ""
  @State private var searchRemote: Bool = false
  @State private var searching: Bool = false

  init() {
    let defaultTab = UserDefaults.standard.string(forKey: "defaultTab") ?? "discover"
    self.selectedTab = ChiiViewTab(defaultTab)
  }

  var body: some View {
    TabView(selection: $selectedTab) {

      NavigationStack {
        ChiiTimelineView()
          .navigationBarTitleDisplayMode(.inline)
          .navigationDestination(for: NavDestination.self) { $0 }
      }
      .tag(ChiiViewTab.timeline)
      .tabItem {
        Label(ChiiViewTab.timeline.title, systemImage: ChiiViewTab.timeline.icon)
      }

      if isAuthenticated {
        NavigationStack {
          ChiiProgressView()
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(for: NavDestination.self) { $0 }
        }
        .tag(ChiiViewTab.progress)
        .tabItem {
          Label(ChiiViewTab.progress.title, systemImage: ChiiViewTab.progress.icon)
        }
      }

      Section {
        NavigationStack(path: $nav) {
          Section {
            if searching {
              SearchView(text: $searchQuery, remote: $searchRemote)
            } else {
              CalendarView()
            }
          }
          .navigationBarTitleDisplayMode(.inline)
          .navigationDestination(for: NavDestination.self) { $0 }
        }
        .searchable(text: $searchQuery, isPresented: $searching)
        .onSubmit(of: .search) {
          searchRemote = true
        }
        .onChange(of: searchQuery) {
          searchRemote = false
        }
        .onContinueUserActivity(CSSearchableItemActionType) { activity in
          handleSearchActivity(activity, nav: $nav)
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
