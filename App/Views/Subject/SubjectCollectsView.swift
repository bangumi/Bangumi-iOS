import SwiftUI

struct SubjectCollectsView: View {
  @AppStorage("isAuthenticated") var isAuthenticated: Bool = false
  @AppStorage("subjectCollectsFilterMode") var subjectCollectsFilterMode: FilterMode = .all

  @Bindable var subject: Subject

  @State private var isLoading: Bool = false

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

  func updateCollects() {
    guard !isLoading else { return }
    isLoading = true

    Task {
      do {
        let resp = try await Chii.shared.getSubjectCollects(
          subject.subjectId,
          mode: subjectCollectsFilterMode,
          limit: 10
        )
        subject.collects = resp.data
        isLoading = false
      } catch {
        Notifier.shared.alert(error: error)
        isLoading = false
      }
    }
  }

  var body: some View {
    VStack(alignment: .leading) {
      VStack(spacing: 2) {
        HStack(alignment: .bottom) {
          Text(title)
            .foregroundStyle(subject.collects.count > 0 ? .primary : .secondary)
            .font(.title3)
          if isAuthenticated {
            Picker("", selection: $subjectCollectsFilterMode) {
              ForEach(FilterMode.allCases, id: \.self) { mode in
                Text(mode.description).tag(mode)
              }
            }
            .disabled(isLoading)
            .pickerStyle(.segmented)
            .frame(width: 80)
            .scaleEffect(0.8)
          }
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
                VStack(spacing: 2) {
                  Text(collect.user.nickname)
                    .lineLimit(1)
                  StarsView(score: Float(collect.interest.rate), size: 8)
                  Label(
                    collect.interest.type.description(subject.typeEnum),
                    systemImage: collect.interest.type.icon
                  )
                  .labelStyle(.compact)
                  .foregroundStyle(.secondary)
                }
                .font(.caption)
                .frame(width: 60)
              }
            }
          }.padding(.horizontal, 2)
        }
        .scrollClipDisabled()
      }
    }
    .animation(.default, value: subject.collects)
    .animation(.default, value: subjectCollectsFilterMode)
    .onChange(of: subjectCollectsFilterMode) { _, _ in
      updateCollects()
    }
  }
}

#Preview {
  ScrollView {
    LazyVStack(alignment: .leading) {
      SubjectCollectsView(subject: Subject.previewAnime)
    }.padding()
  }
}
