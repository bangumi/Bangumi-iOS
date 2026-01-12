import SwiftUI

struct ChiiDiscoverView: View {

  @State private var query: String = ""
  @State private var searching: Bool = false
  @State private var remote: Bool = false

  func refresh() async {
    do {
      try await Chii.shared.loadCalendar()
      try await Chii.shared.loadTrendingSubjects()
    } catch {
      Notifier.shared.alert(error: error)
    }
  }

  var body: some View {
    GeometryReader { geometry in
      VStack {
        if searching {
          SearchView(text: $query, searching: $searching, remote: $remote)
        } else {
          ScrollView {
            VStack {
              CalendarSlimView()
              TrendingSubjectView(width: geometry.size.width)
            }
          }
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
    .onChange(of: query) {
      remote = false
    }
    .onSubmit(of: .search) {
      remote = true
    }
  }
}
