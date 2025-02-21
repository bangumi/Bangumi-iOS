import SwiftUI

struct ChiiRakuenView: View {
  var body: some View {
    ScrollView {
      VStack(spacing: 16) {
        RecentGroupTopicsView()
        TrendingSubjectTopicsView()
      }.padding(8)
    }
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
