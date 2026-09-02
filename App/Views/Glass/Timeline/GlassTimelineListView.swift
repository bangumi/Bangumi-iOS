import SwiftUI

struct GlassTimelineListView: View {
  @AppStorage("isAuthenticated") private var isAuthenticated: Bool = false
  @AppStorage("profile") private var profile: Profile = Profile()
  @AppStorage("timelineViewMode") private var timelineViewMode: TimelineViewMode = .friends

  @State private var showInput = false

  @State private var exhausted: Bool = false
  @State private var loading: Bool = false
  @State private var lastID: Int?
  @State private var fetched: [Int: Bool] = [:]
  @State private var items: [TimelineDTO] = []

  @Environment(\.theme) private var theme

  private var activeMode: TimelineViewMode {
    isAuthenticated ? timelineViewMode : .all
  }

  private func fetchPage(until: Int?) async throws -> [TimelineDTO] {
    switch activeMode {
    case .all:
      return try await TimelineService.getTimeline(mode: .all, limit: 20, until: until)
    case .friends:
      return try await TimelineService.getTimeline(mode: .friends, limit: 20, until: until)
    case .me:
      return try await UserService.getUserTimeline(
        username: profile.username, limit: 20, until: until)
    }
  }

  func reload() async {
    do {
      let data = try await fetchPage(until: nil)
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
      let data = try await fetchPage(until: triggerID)
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

  private func loadInitialPageIfNeeded() {
    guard items.isEmpty, !loading else { return }
    withAnimation(.default) {
      loading = true
    }
    Task {
      await reload()
      withAnimation(.default) {
        loading = false
      }
    }
  }

  private func reloadForModeChange() {
    Task {
      withAnimation(.default) {
        loading = true
      }
      await reload()
      withAnimation(.default) {
        loading = false
      }
    }
  }

  var body: some View {
    let rows = items.timelineListRows(lastID: lastID)

    ScrollView {
      LazyVStack(alignment: .leading, spacing: theme.metrics.listSpacing) {
        if !isAuthenticated {
          GlassLoginCard(
            title: "登录 Bangumi 番组计划",
            subtitle: "管理你的收藏与追番进度，关注好友动态，加入超展开的讨论。",
            buttonTitle: "登录 / 注册",
            footnote: "未登录也可以浏览全站公开动态"
          )
        }

        ForEach(rows) { row in
          GlassTimelineItemView(item: row.item)
            .task(id: row.nextPageTriggerID) {
              if let triggerID = row.nextPageTriggerID {
                await loadNextPage(triggerID: triggerID)
              }
            }
        }

        if loading {
          loadingFooter
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

        if !isAuthenticated {
          GlassLoginHintBar(text: "登录后可查看好友动态、发表吐槽与回应。")
        }
      }
      .padding(.horizontal, theme.metrics.screenPadding)
      .padding(.top, 4)
      .padding(.bottom, isAuthenticated ? 88 : 26)
    }
    .overlay(alignment: .bottomTrailing) {
      if isAuthenticated {
        GlassComposeFAB {
          showInput = true
        }
        .disabled(showInput)
        .padding(.trailing, 18)
        .padding(.bottom, 16)
      }
    }
    .sheet(isPresented: $showInput) {
      GlassTimelineSayView()
    }
    .onAppear(perform: loadInitialPageIfNeeded)
    .onChange(of: timelineViewMode) {
      guard isAuthenticated else { return }
      reloadForModeChange()
    }
    .onChange(of: isAuthenticated) {
      reloadForModeChange()
    }
    .refreshable {
      await reload()
    }
  }

  private var loadingFooter: some View {
    HStack(spacing: 8) {
      Spacer()
      ProgressView()
      Text(items.isEmpty ? "正在刷新…" : "加载更多…")
        .font(.caption)
        .foregroundStyle(theme.tertiaryText)
      Spacer()
    }
    .padding(.vertical, 18)
  }
}
