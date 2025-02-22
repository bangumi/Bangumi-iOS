import SwiftUI

enum RakuenTab {
  case latestGroupTopics
  case trendingSubjectTopics
}

struct ChiiRakuenView: View {
  @State private var selectedTab: RakuenTab = .latestGroupTopics

  var body: some View {
    VStack(spacing: 5) {
      Picker("Tab", selection: $selectedTab) {
        Text("最新小组话题").tag(RakuenTab.latestGroupTopics)
        Text("热门条目讨论").tag(RakuenTab.trendingSubjectTopics)
      }
      .pickerStyle(.segmented)
      .padding(.horizontal, 8)
      TabView(selection: $selectedTab) {
        RecentGroupTopicsView()
          .tag(RakuenTab.latestGroupTopics)
          .tabItem {
            Text("最新小组话题")
          }
        TrendingSubjectTopicsView()
          .tag(RakuenTab.trendingSubjectTopics)
          .tabItem {
            Text("热门条目讨论")
          }
      }
    }
    .tabViewStyle(.page)
    .animation(.default, value: selectedTab)
    .navigationTitle("超展开")
    .toolbarTitleDisplayMode(.inline)
    .toolbar {
      ToolbarItem(placement: .navigationBarTrailing) {
        Menu {
          Section {
            ForEach(SubjectTopicFilterMode.allCases, id: \.self) { mode in
              NavigationLink(value: NavDestination.rakuenSubjectTopics(mode)) {
                Text(mode.description)
              }
            }
          } header: {
            Text("条目讨论")
          }
          Divider()
          Section {
            ForEach(GroupTopicFilterMode.allCases, id: \.self) { mode in
              NavigationLink(value: NavDestination.rakuenGroupTopics(mode)) {
                Text(mode.description)
              }
            }
          } header: {
            Text("小组话题")
          }
          Divider()
          Section {
            NavigationLink(value: NavDestination.groupList) {
              Text("小组列表")
            }
          } header: {
            Text("小组")
          }
        } label: {
          Image(systemName: "ellipsis.circle")
        }
      }
    }
  }
}
