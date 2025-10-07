import SwiftUI

struct SubjectCollectsView: View {
  @Environment(Subject.self) var subject
  @AppStorage("subjectCollectsFilterMode") var subjectCollectsFilterMode: FilterMode = .all

  var title: String {
    switch subject.typeEnum {
    case .book:
      if subject.series {
        return "谁读这本书?"
      } else {
        return "谁读这本书?"
      }
    case .anime:
      return "谁看这部动画?"
    case .music:
      return "谁听这张唱片?"
    case .game:
      return "谁玩这部游戏?"
    case .real:
      return "谁看这部影视?"
    default:
      return "谁收藏这个条目?"
    }
  }

  var moreText: String {
    switch subjectCollectsFilterMode {
    case .all:
      return "更多用户 »"
    case .friends:
      return "更多好友 »"
    }
  }

  var emptyText: String {
    switch subjectCollectsFilterMode {
    case .all:
      return "暂无用户收藏"
    case .friends:
      return "暂无好友收藏"
    }
  }

  var body: some View {
    VStack(spacing: 2) {
      HStack(alignment: .bottom) {
        Text(title)
          .foregroundStyle(subject.collects.count > 0 ? .primary : .secondary)
          .font(.title3)
        Spacer()
        if subject.collects.count > 0 {
          NavigationLink(value: NavDestination.subjectCollectsList(subject.subjectId)) {
            Text(moreText).font(.caption)
          }.buttonStyle(.navigation)
        }
      }
      Divider()
    }.padding(.top, 5)

    if subject.collects.isEmpty {
      HStack {
        Spacer()
        Text(emptyText)
          .font(.caption)
          .foregroundStyle(.secondary)
        Spacer()
      }.padding(.bottom, 5)
    } else {
      ScrollView(.horizontal, showsIndicators: false) {
        LazyHStack(alignment: .top, spacing: 8) {
          ForEach(subject.collects.prefix(10)) { collect in
            VStack(spacing: 4) {
              ImageView(img: collect.user.avatar?.large)
                .imageStyle(width: 60, height: 60)
                .imageType(.avatar)
                .contextMenu {
                  NavigationLink(value: NavDestination.user(collect.user.username)) {
                    Label("查看用户主页", systemImage: "person.circle")
                  }
                } preview: {
                  SubjectCollectRowView(collect: collect, subjectType: subject.typeEnum)
                    .padding()
                    .frame(idealWidth: 360)
                }
              Text(collect.user.nickname)
                .font(.caption2)
                .lineLimit(1)
                .frame(width: 60)
              StarsView(score: Float(collect.interest.rate), size: 8)
            }
          }
        }.padding(.horizontal, 2)
      }.animation(.default, value: subject.collects)
    }
  }
}

#Preview {
  ScrollView {
    LazyVStack(alignment: .leading) {
      SubjectCollectsView().environment(Subject.previewAnime)
    }.padding()
  }
}
