import SwiftUI

struct GlassSearchRootView: View {
  @Environment(\.theme) private var theme

  @State private var query: String = ""
  @State private var remote: Bool = false
  @State private var searchType: SearchType = .subject
  @State private var subjectType: SubjectType = .none
  @State private var showsSearch = false
  @State private var didInitialRefresh = false
  @State private var refreshing = false
  @State private var trendingReloadToken = 0
  @State private var keepRemoteOnQueryChange = false
  @FocusState private var searchFocused: Bool

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
    await refreshTrendingSubjects()
  }

  private func refreshInitiallyIfNeeded() {
    guard !didInitialRefresh else { return }
    didInitialRefresh = true
    Task {
      await refresh()
    }
  }

  private func syncShowsSearch() {
    let next = !query.isEmpty
    guard showsSearch != next else { return }
    withAnimation(.default) {
      showsSearch = next
    }
  }

  private var searchCancelAction: (() -> Void)? {
    guard searchFocused || !query.isEmpty else { return nil }
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

  private func submitSearch() {
    SearchHistory.record(query)
    withAnimation(.default) {
      remote = true
    }
  }

  private func selectKeyword(_ keyword: String) {
    keepRemoteOnQueryChange = true
    query = keyword
    searchFocused = false
    SearchHistory.record(keyword)
    withAnimation(.default) {
      remote = true
    }
  }

  private var typeChips: some View {
    ScrollView(.horizontal, showsIndicators: false) {
      HStack(spacing: 6) {
        chip(for: .none)
        ForEach(SubjectType.allTypes) { type in
          chip(for: type)
        }
      }
      .padding(.horizontal, 2)
    }
    .scrollClipDisabled()
  }

  private func chip(for type: SubjectType) -> some View {
    GlassChip(title: type.description, isSelected: subjectType == type) {
      withAnimation(.default) {
        subjectType = type
      }
    }
  }

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: theme.metrics.listSpacing) {
        GlassSearchField(
          text: $query,
          prompt: "搜索条目，角色，人物",
          isFocused: $searchFocused,
          onSubmit: submitSearch,
          onCancel: searchCancelAction
        )
        .searchInputTraits()

        GlassSegmented(
          selection: $searchType.animated(),
          items: [SearchType.subject, .character, .person]
        ) { item in
          Text(item.glassTitle)
        }
        if searchType == .subject {
          typeChips
        }

        if showsSearch {
          GlassSearchView(
            text: query, remote: $remote,
            searchType: $searchType, subjectType: $subjectType
          )
        } else {
          SearchHistorySection(onSelect: selectKeyword)
          if searchType == .subject {
            SearchSuggestionSection(
              subjectType: subjectType,
              reloadToken: trendingReloadToken,
              onSelect: selectKeyword
            )
          }
        }
      }
      .padding(.horizontal, theme.metrics.screenPadding)
      .padding(.top, 8)
      .padding(.bottom, 26)
    }
    .refreshable {
      await refresh()
    }
    .navigationTitle("搜索")
    .toolbarTitleDisplayMode(.inline)
    .onAppear {
      showsSearch = !query.isEmpty
      refreshInitiallyIfNeeded()
      if query.isEmpty {
        searchFocused = true
      }
    }
    .onChange(of: query) { _, _ in
      syncShowsSearch()
      if keepRemoteOnQueryChange {
        keepRemoteOnQueryChange = false
      } else if remote {
        withAnimation(.default) {
          remote = false
        }
      }
    }
  }
}
