import SwiftUI

struct GlassUserTimelineFeedView: View {
  let user: SlimUserDTO

  @AppStorage("profile") private var profile: Profile = Profile()

  @State private var exhausted: Bool = false
  @State private var loading: Bool = false
  @State private var lastID: Int?
  @State private var fetched: [Int: Bool] = [:]
  @State private var items: [TimelineDTO] = []

  @Environment(\.theme) private var theme

  var title: String {
    if user.id == profile.id {
      return "我的时空管理局"
    } else {
      return "\(user.nickname)的时空管理局"
    }
  }

  func reload() async {
    do {
      let data = try await UserService.getUserTimeline(
        username: user.username, limit: 20, until: nil)
      if data.count == 0 {
        Notifier.shared.notify(message: "没有新动态")
        return
      }
      withAnimation(.default) {
        exhausted = false
        items = data
        fetched = [:]
        lastID = data.last?.id
      }
    } catch {
      Notifier.shared.alert(error: error)
    }
  }

  func loadNextPage(triggerID: TimelineDTO.ID) async {
    if loading {
      return
    }
    if exhausted {
      return
    }
    if lastID != triggerID {
      return
    }
    if fetched[triggerID] == true {
      return
    }
    withAnimation(.default) {
      loading = true
    }
    do {
      let data = try await UserService.getUserTimeline(
        username: user.username, limit: 20, until: triggerID)
      if data.count == 0 {
        exhausted = true
      }
      fetched[triggerID] = true
      items.append(contentsOf: data)
      lastID = data.last?.id
    } catch {
      Notifier.shared.alert(error: error)
    }
    withAnimation(.default) {
      loading = false
    }
  }

  var body: some View {
    let rows = items.timelineListRows(lastID: lastID)

    ScrollView {
      LazyVStack(alignment: .leading, spacing: theme.metrics.listSpacing) {
        header
        ForEach(rows) { row in
          GlassTimelineItemView(item: row.item)
            .task(id: row.nextPageTriggerID) {
              if let triggerID = row.nextPageTriggerID {
                await loadNextPage(triggerID: triggerID)
              }
            }
        }
        if loading {
          HStack {
            Spacer()
            ProgressView()
            Spacer()
          }
          .padding(.vertical, 18)
        } else if items.isEmpty {
          GlassEmptyCard(
            systemImage: "clock.arrow.circlepath",
            title: "暂无动态",
            description: "下拉可以刷新时间线")
        } else if exhausted {
          Text("没有更多动态了")
            .font(.caption)
            .foregroundStyle(theme.tertiaryText)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
        }
      }
      .padding(.horizontal, theme.metrics.screenPadding)
      .padding(.top, 4)
      .padding(.bottom, 26)
    }
    .navigationTitle(title)
    .navigationBarTitleDisplayMode(.inline)
    .task {
      if items.count > 0 {
        return
      }
      withAnimation(.default) {
        loading = true
      }
      await reload()
      withAnimation(.default) {
        loading = false
      }
    }
    .refreshable {
      await reload()
    }
  }

  private var header: some View {
    CardView(
      padding: theme.metrics.cardPadding,
      cornerRadius: theme.metrics.cardRadius,
      role: .strong
    ) {
      HStack(spacing: 11) {
        ImageView(img: user.avatar?.large)
          .imageStyle(width: 44, height: 44, alignment: .center)
          .imageType(.avatar)
          .imageLink(user.link)
        VStack(alignment: .leading, spacing: 3) {
          Text(user.nickname.withLink(user.link, linkColor: theme.link))
            .font(.headline)
            .foregroundStyle(theme.cardTitle)
            .lineLimit(1)
          Text("@\(user.username)")
            .font(.footnote)
            .foregroundStyle(theme.secondaryText)
            .lineLimit(1)
        }
        Spacer(minLength: 0)
      }
    }
  }
}
