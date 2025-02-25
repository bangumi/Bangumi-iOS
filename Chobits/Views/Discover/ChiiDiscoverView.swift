import SwiftUI

struct ChiiDiscoverView: View {

  @State private var searchQuery: String = ""
  @State private var searching: Bool = false

  func refresh() async {
    do {
      try await Chii.shared.loadCalendar()
      try await Chii.shared.loadTrendingSubjects()
    } catch {
      Notifier.shared.alert(error: error)
    }
  }

  var body: some View {
    Section {
      if searching {
        SearchView(text: $searchQuery, searching: $searching)
      } else {
        ScrollView {
          VStack {
            CalendarSlimView()
            TrendingSubjectView()
          }.padding(.horizontal, 8)
        }.refreshable {
          await refresh()
        }
      }
    }
    .searchable(
      text: $searchQuery, isPresented: $searching,
      placement: .navigationBarDrawer(displayMode: .always))
  }
}
