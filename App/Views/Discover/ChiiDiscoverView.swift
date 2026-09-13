import SwiftUI

struct ChiiDiscoverView: View {
  @Environment(\.theme) private var theme

  @AppStorage("isAuthenticated") var isAuthenticated: Bool = false
  @AppStorage("profile") var profile: Profile = Profile()

  @State private var didInitialRefresh = false
  @State private var refreshing = false
  @State private var calendarReloadToken = 0
  @State private var trendingReloadToken = 0

  private func refreshCalendar() async {
    do {
      try await DiscoveryRepository.loadCalendar()
      calendarReloadToken += 1
    } catch {
      Notifier.shared.alert(error: error)
    }
  }

  private func refreshTrendingSubjects() async {
    do {
      try await DiscoveryRepository.loadTrendingSubjects()
      trendingReloadToken += 1
    } catch {
      Notifier.shared.alert(error: error)
    }
  }

  private func refresh() async {
    guard !refreshing else { return }
    refreshing = true
    defer {
      refreshing = false
    }

    async let calendar: Void = refreshCalendar()
    async let trending: Void = refreshTrendingSubjects()
    _ = await (calendar, trending)
  }

  private func refreshInitiallyIfNeeded() {
    guard !didInitialRefresh else { return }
    didInitialRefresh = true
    Task {
      await refresh()
    }
  }

  @ViewBuilder
  var body: some View {
    if theme.isClassic {
      classicBody
    } else {
      GlassDiscoverView()
    }
  }

  private var classicBody: some View {
    GeometryReader { geometry in
      ScrollView {
        VStack {
          CalendarSlimView(reloadToken: calendarReloadToken)
          TrendingSubjectView(
            width: geometry.size.width,
            reloadToken: trendingReloadToken
          )
        }
      }
    }
    .refreshable {
      await refresh()
    }
    .navigationTitle("发现")
    .toolbarTitleDisplayMode(.inline)
    .toolbar {
      ToolbarItemGroup(placement: .topBarLeading) {
        if isAuthenticated {
          NavigationLink(value: NavDestination.profileHome) {
            ProfileToolbarAvatarView(imageURL: profile.avatar?.large)
          }
          .buttonStyle(.plain)
          .accessibilityLabel("我的")
        }
      }
      ToolbarItemGroup(placement: .topBarTrailing) {
        if isAuthenticated, profile.canAccessWikiTools {
          NavigationLink(value: NavDestination.wikiHome) {
            Image(systemName: "pencil.and.list.clipboard")
          }
        }
      }
    }
    .onAppear {
      refreshInitiallyIfNeeded()
    }
  }
}
