import SwiftUI

struct ChiiDiscoverView: View {

  @State private var query: String = ""
  @State private var searching: Bool = false
  @State private var remote: Bool = false
  @State private var showsSearch = false
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

  var body: some View {
    GeometryReader { geometry in
      VStack {
        if !showsSearch {
          ScrollView {
            VStack {
              CalendarSlimView(reloadToken: calendarReloadToken)
              TrendingSubjectView(
                width: geometry.size.width,
                reloadToken: trendingReloadToken
              )
            }
          }
        } else {
          SearchView(text: $query, remote: $remote)
        }
      }
    }
    .refreshable {
      await refresh()
    }
    .navigationTitle("发现")
    .toolbarTitleDisplayMode(.inline)
    .searchable(
      text: $query, isPresented: $searching,
      placement: .navigationBarDrawer(displayMode: .always),
      prompt: "搜索条目，角色，人物"
    )
    .searchInputTraits()
    .onAppear {
      showsSearch = !query.isEmpty
      refreshInitiallyIfNeeded()
    }
    .onChange(of: query) { _, newValue in
      let nextShowsSearch = !newValue.isEmpty
      if showsSearch != nextShowsSearch {
        withAnimation(.default) {
          showsSearch = nextShowsSearch
        }
      }
      if remote {
        withAnimation(.default) {
          remote = false
        }
      }
    }
    .onSubmit(of: .search) {
      withAnimation(.default) {
        remote = true
      }
    }
  }
}
