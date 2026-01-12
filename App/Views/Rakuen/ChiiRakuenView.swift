import SwiftUI

enum RakuenListMode: String, CaseIterable {
  case subjectTrending
  case subjectLatest
  case groupAll
  case groupJoined
  case groupCreated
  case groupReplied

  var description: String {
    switch self {
    case .subjectTrending:
      return "热门"
    case .subjectLatest:
      return "最新"
    case .groupAll:
      return "全部"
    case .groupJoined:
      return "参加的"
    case .groupCreated:
      return "发表的"
    case .groupReplied:
      return "回复的"
    }
  }

  var category: RakuenCategory {
    switch self {
    case .subjectTrending, .subjectLatest:
      return .subject
    case .groupAll, .groupJoined, .groupCreated, .groupReplied:
      return .group
    }
  }

  var subjectTopicMode: SubjectTopicFilterMode? {
    switch self {
    case .subjectTrending:
      return .trending
    case .subjectLatest:
      return .latest
    default:
      return nil
    }
  }

  var groupTopicMode: GroupTopicFilterMode? {
    switch self {
    case .groupAll:
      return .all
    case .groupJoined:
      return .joined
    case .groupCreated:
      return .created
    case .groupReplied:
      return .replied
    default:
      return nil
    }
  }

  var requiresLogin: Bool {
    switch self {
    case .groupJoined, .groupCreated, .groupReplied:
      return true
    default:
      return false
    }
  }
}

enum RakuenCategory: String, CaseIterable {
  case subject
  case group

  var description: String {
    switch self {
    case .subject:
      return "条目讨论"
    case .group:
      return "小组话题"
    }
  }

  var modes: [RakuenListMode] {
    switch self {
    case .subject:
      return [.subjectTrending, .subjectLatest]
    case .group:
      return [.groupAll, .groupJoined, .groupCreated, .groupReplied]
    }
  }
}

struct ChiiRakuenView: View {
  @AppStorage("rakuenListMode") var rakuenListMode: RakuenListMode = .subjectTrending
  @AppStorage("isAuthenticated") var isAuthenticated = false

  @State private var reloader = false

  var body: some View {
    ScrollView {
      VStack(spacing: 0) {
        HotGroupsView()
        VStack(alignment: .leading, spacing: 8) {
          modeSelectorView.padding(4)
          contentView
        }
        .padding(.top, 8)
      }.padding(.horizontal, 8)
    }
    .refreshable {
      reloader.toggle()
    }
    .animation(.default, value: rakuenListMode)
    .navigationTitle("超展开")
    .toolbarTitleDisplayMode(.inline)
    .toolbar {
      ToolbarItem(placement: .topBarTrailing) {
        Menu {
          Menu {
            ForEach(SubjectTopicFilterMode.allCases, id: \.self) { mode in
              NavigationLink(value: NavDestination.rakuenSubjectTopics(mode)) {
                Text(mode.description)
              }
            }
          } label: {
            Text("条目讨论")
          }

          Menu {
            ForEach(GroupTopicFilterMode.allCases, id: \.self) { mode in
              if isAuthenticated || mode == .all {
                NavigationLink(value: NavDestination.rakuenGroupTopics(mode)) {
                  Text(mode.description)
                }
              }
            }
          } label: {
            Text("小组话题")
          }
          Divider()

          Menu {
            ForEach(GroupFilterMode.allCases, id: \.self) { mode in
              if isAuthenticated || mode == .all {
                NavigationLink(value: NavDestination.groupList(mode)) {
                  Text(mode.description)
                }
              }
            }
          } label: {
            Text("浏览小组")
          }
        } label: {
          Image(systemName: "ellipsis.circle")
        }
      }
    }
    .onAppear {
      if !isAuthenticated && rakuenListMode.requiresLogin {
        rakuenListMode = .subjectTrending
      }
    }
  }

  private var modeSelectorView: some View {
    ScrollView(.horizontal, showsIndicators: false) {
      HStack(spacing: 16) {
        ForEach(RakuenCategory.allCases, id: \.self) { category in
          categorySection(category)
        }
      }
    }
    .scrollClipDisabled()
  }

  private func categorySection(_ category: RakuenCategory) -> some View {
    let availableModes = category.modes.filter { isAuthenticated || !$0.requiresLogin }
    if availableModes.isEmpty {
      return AnyView(EmptyView())
    }
    return AnyView(
      HStack(spacing: 8) {
        Text(category.description)
          .font(.footnote)
          .foregroundStyle(.secondary)
          .padding(.trailing, 4)

        ForEach(availableModes, id: \.self) { mode in
          Button {
            rakuenListMode = mode
          } label: {
            Text(mode.description)
          }.adaptiveButtonStyle(rakuenListMode == mode ? .borderedProminent : .bordered)
        }
      })
  }

  @ViewBuilder
  private var contentView: some View {
    switch rakuenListMode.category {
    case .subject:
      if let mode = rakuenListMode.subjectTopicMode {
        CachedSubjectTopicListView(mode: mode, reloader: $reloader)
      }
    case .group:
      if let mode = rakuenListMode.groupTopicMode {
        CachedGroupTopicListView(mode: mode, reloader: $reloader)
      }
    }
  }
}
