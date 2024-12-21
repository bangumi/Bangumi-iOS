import CoreSpotlight
import OSLog
import SwiftUI

@available(iOS 18.0, *)
struct PadView: View {
  @AppStorage("isAuthenticated") var isAuthenticated: Bool = false
  @AppStorage("isolationMode") var isolationMode: Bool = false

  @State private var selectedTab: ChiiViewTab

  @State private var nav: NavigationPath = NavigationPath()
  @State private var searchQuery: String = ""
  @State private var searchRemote: Bool = false
  @State private var searching: Bool = false

  @State private var profile: User?

  init() {
    let defaultTab = UserDefaults.standard.string(forKey: "defaultTab") ?? "discover"
    self.selectedTab = ChiiViewTab(defaultTab)
  }

  var body: some View {
    TabView(selection: $selectedTab) {
      Tab(ChiiViewTab.timeline.title, systemImage: ChiiViewTab.timeline.icon, value: .timeline) {
        NavigationStack {
          ChiiTimelineView()
            .navigationDestination(for: NavDestination.self) { $0 }
        }
      }

      if isAuthenticated {
        Tab(ChiiViewTab.progress.title, systemImage: ChiiViewTab.progress.icon, value: .progress) {
          NavigationStack {
            ChiiProgressView()
              .navigationDestination(for: NavDestination.self) { $0 }
          }
        }
      }

      Tab(
        ChiiViewTab.discover.title, systemImage: ChiiViewTab.discover.icon,
        value: .discover, role: .search
      ) {
        NavigationStack(path: $nav) {
          Section {
            if searching {
              SearchView(text: $searchQuery, remote: $searchRemote)
            } else {
              CalendarView()
            }
          }.navigationDestination(for: NavDestination.self) { $0 }
        }
        .searchable(text: $searchQuery, isPresented: $searching, placement: .toolbar)
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
    }.tabViewStyle(.sidebarAdaptable)
  }
}
