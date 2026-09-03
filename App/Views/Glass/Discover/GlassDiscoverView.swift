import SwiftUI

struct GlassDiscoverView: View {
  @AppStorage("isAuthenticated") var isAuthenticated: Bool = false
  @AppStorage("profile") var profile: Profile = Profile()

  @Environment(\.theme) private var theme

  @State private var query: String = ""
  @State private var remote: Bool = false
  @State private var showsSearch = false
  @State private var didInitialRefresh = false
  @State private var refreshing = false
  @State private var calendarReloadToken = 0
  @State private var trendingReloadToken = 0
  @FocusState private var searchFocused: Bool

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

  private func syncShowsSearch() {
    let next = searchFocused || !query.isEmpty
    guard showsSearch != next else { return }
    withAnimation(.default) {
      showsSearch = next
    }
  }

  private var searchCancelAction: (() -> Void)? {
    guard showsSearch else { return nil }
    return { cancelSearch() }
  }

  private func cancelSearch() {
    searchFocused = false
    if !query.isEmpty {
      query = ""
    }
    if remote {
      remote = false
    }
    syncShowsSearch()
  }

  var body: some View {
    GeometryReader { geometry in
      ScrollView {
        VStack(alignment: .leading, spacing: theme.metrics.listSpacing) {
          GlassSearchField(
            text: $query,
            prompt: "搜索条目，角色，人物",
            isFocused: $searchFocused,
            onSubmit: {
              withAnimation(.default) {
                remote = true
              }
            },
            onCancel: searchCancelAction
          )
          .searchInputTraits()

          if showsSearch {
            GlassSearchView(text: query, remote: $remote)
          } else {
            GlassCalendarSection(reloadToken: calendarReloadToken)
            GlassTrendingSection(
              width: geometry.size.width,
              reloadToken: trendingReloadToken
            )
          }
        }
        .padding(.horizontal, theme.metrics.screenPadding)
        .padding(.top, 8)
        .padding(.bottom, 26)
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
        }
      }
      ToolbarItemGroup(placement: .topBarTrailing) {
        if isAuthenticated, profile.canAccessWikiTools {
          NavigationLink(value: NavDestination.wikiHome) {
            ToolbarCircle {
              Image(systemName: "pencil.and.list.clipboard")
            }
          }
          .buttonStyle(.plain)
        }
      }
    }
    .onAppear {
      showsSearch = !query.isEmpty
      refreshInitiallyIfNeeded()
    }
    .onChange(of: query) { _, _ in
      syncShowsSearch()
      if remote {
        withAnimation(.default) {
          remote = false
        }
      }
    }
    .onChange(of: searchFocused) { _, _ in
      syncShowsSearch()
    }
  }
}
