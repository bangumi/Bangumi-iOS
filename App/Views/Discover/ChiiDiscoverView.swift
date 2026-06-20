import SwiftUI

struct ChiiDiscoverView: View {

  @State private var query: String = ""
  @State private var searching: Bool = false
  @State private var remote: Bool = false
  @State private var showsSearch = false

  func refresh() async {
    do {
      try await DiscoveryRepository.loadCalendar()
      try await DiscoveryRepository.loadTrendingSubjects()
    } catch {
      Notifier.shared.alert(error: error)
    }
  }

  var body: some View {
    GeometryReader { geometry in
      VStack {
        if !showsSearch {
          ScrollView {
            VStack {
              CalendarSlimView()
              TrendingSubjectView(width: geometry.size.width)
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
