import SwiftUI

struct ChiiSearchView: View {
  @Environment(\.theme) private var theme

  @State private var query: String = ""
  @State private var searching: Bool = false
  @State private var remote: Bool = false
  @State private var searchType: SearchType = .subject
  @State private var subjectType: SubjectType = .none
  @State private var showsSearch = false
  @State private var didInitialRefresh = false
  @State private var refreshing = false
  @State private var trendingReloadToken = 0
  @State private var keepRemoteOnQueryChange = false

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

  private func submitSearch() {
    SearchHistory.record(query)
    withAnimation(.default) {
      remote = true
    }
  }

  private func selectKeyword(_ keyword: String) {
    keepRemoteOnQueryChange = true
    query = keyword
    searching = false
    SearchHistory.record(keyword)
    withAnimation(.default) {
      remote = true
    }
  }

  @ViewBuilder
  var body: some View {
    if theme.isClassic {
      classicBody
    } else {
      GlassSearchRootView()
    }
  }

  private var classicBody: some View {
    VStack(spacing: 4) {
      VStack(spacing: 4) {
        HStack(spacing: 4) {
          Picker("SearchType", selection: $searchType.animated()) {
            Text("条目").tag(SearchType.subject)
            Text("角色").tag(SearchType.character)
            Text("人物").tag(SearchType.person)
          }.pickerStyle(.segmented)
          Image(systemName: remote ? "globe" : "internaldrive")
            .foregroundColor(remote ? .blue : .green)
            .frame(width: 20)
            .padding(.horizontal, 4)
        }
        if searchType == .subject {
          Picker("Subject Type", selection: $subjectType.animated()) {
            Text("全部").tag(SubjectType.none)
            ForEach(SubjectType.allTypes) { type in
              Text(type.description).tag(type)
            }
          }.pickerStyle(.segmented)
        }
      }
      .padding(.horizontal, 8)
      if !showsSearch {
        ScrollView {
          VStack(spacing: 16) {
            SearchHistorySection(onSelect: selectKeyword)
            if searchType == .subject {
              SearchSuggestionSection(
                subjectType: subjectType,
                reloadToken: trendingReloadToken,
                onSelect: selectKeyword
              )
            }
          }
          .padding(.horizontal, 8)
          .padding(.vertical, 8)
        }
        .refreshable {
          await refresh()
        }
      } else {
        SearchView(
          text: $query, remote: $remote,
          searchType: $searchType, subjectType: $subjectType
        )
      }
    }
    .padding(.top, 4)
    .navigationTitle("搜索")
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
      if query.isEmpty {
        searching = true
      }
    }
    .onChange(of: query) { _, newValue in
      let nextShowsSearch = !newValue.isEmpty
      if showsSearch != nextShowsSearch {
        withAnimation(.default) {
          showsSearch = nextShowsSearch
        }
      }
      if keepRemoteOnQueryChange {
        keepRemoteOnQueryChange = false
      } else if remote {
        withAnimation(.default) {
          remote = false
        }
      }
    }
    .onSubmit(of: .search) {
      submitSearch()
    }
  }
}
