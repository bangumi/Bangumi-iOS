import SwiftUI

enum RakuenTab {
  case latestGroupTopics
  case trendingSubjectTopics
}

struct ChiiRakuenView: View {
  @State private var reloader = false

  var body: some View {
    ScrollView {
      VStack {
        JoinedGroupsView()
        VStack(alignment: .leading, spacing: 5) {
          HStack {
            Text(GroupTopicFilterMode.joined.description)
              .font(.title3)
            Spacer()
            Menu {
              ForEach(GroupTopicFilterMode.allCases, id: \.self) { mode in
                NavigationLink(value: NavDestination.rakuenGroupTopics(mode)) {
                  Text(mode.description)
                }
              }
            } label: {
              Text("更多 »")
                .font(.footnote)
            }.buttonStyle(.navigation)
          }.padding(.top, 8)
          RakuenGroupTopicListView(mode: .joined, reloader: $reloader)
        }
      }.padding(.horizontal, 8)
    }
    .refreshable {
      reloader.toggle()
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
            ForEach(GroupFilterMode.allCases, id: \.self) { mode in
              NavigationLink(value: NavDestination.groupList(mode)) {
                Text(mode.description)
              }
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
