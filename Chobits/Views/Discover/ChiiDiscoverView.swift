import SwiftUI

enum DiscoverTab {
  case calendar
  case trending
}

struct ChiiDiscoverView: View {
  @State private var selectedTab: DiscoverTab = .calendar

  @State private var searchQuery: String = ""
  @State private var searching: Bool = false

  var body: some View {
    Section {
      if searching {
        SearchView(text: $searchQuery, searching: $searching)
      } else {
        VStack(spacing: 5) {
          Picker("Tab", selection: $selectedTab) {
            Text("每日放送").tag(DiscoverTab.calendar)
            Text("热门条目").tag(DiscoverTab.trending)
          }
          .pickerStyle(.segmented)
          .padding(.horizontal, 8)
          TabView(selection: $selectedTab) {
            CalendarSlimView()
              .tag(DiscoverTab.calendar)
            TrendingSubjectView()
              .tag(DiscoverTab.trending)
          }
          .tabViewStyle(.page)
          .animation(.default, value: selectedTab)
        }
      }
    }
    .animation(.default, value: selectedTab)
    .searchable(
      text: $searchQuery, isPresented: $searching,
      placement: .navigationBarDrawer(displayMode: .always))
  }
}
