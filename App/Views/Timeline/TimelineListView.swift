import OSLog
import SwiftUI

struct TimelineListView: View {
  @AppStorage("isAuthenticated") var isAuthenticated: Bool = false
  @AppStorage("profile") var profile: Profile = Profile()
  @AppStorage("timelineViewMode") var timelineViewMode: TimelineViewMode = .friends
  @AppStorage("timelineLiveMode") var liveMode: Bool = false

  @State private var showInput = false

  @State private var exhausted: Bool = false
  @State private var loading: Bool = false
  @State private var didFetch: Bool = false
  @State private var lastID: Int?
  @State private var fetched: [Int: Bool] = [:]
  @State private var items: [TimelineDTO] = []

  func reload() async {
    do {
      var data: [TimelineDTO] = []
      switch timelineViewMode {
      case .all:
        data = try await TimelineService.getTimeline(mode: .all, limit: 20, until: nil)
      case .friends:
        data = try await TimelineService.getTimeline(mode: .friends, limit: 20, until: nil)
      case .me:
        data = try await UserService.getUserTimeline(
          username: profile.username, limit: 20, until: nil)
      }
      withAnimation(.layoutShift) {
        didFetch = true
      }
      if data.count == 0 {
        // An empty list already gets the empty-state card; the toast only earns
        // its keep when a refresh finds nothing new on top of existing items.
        if !items.isEmpty {
          Notifier.shared.notify(message: "没有新动态")
        }
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
      var data: [TimelineDTO] = []
      switch timelineViewMode {
      case .all:
        data = try await TimelineService.getTimeline(mode: .all, limit: 20, until: triggerID)
      case .friends:
        data = try await TimelineService.getTimeline(mode: .friends, limit: 20, until: triggerID)
      case .me:
        data = try await UserService.getUserTimeline(
          username: profile.username, limit: 20, until: triggerID)
      }
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

  /// `.me` has no SSE counterpart, and anonymous users only see the auth card here,
  /// so live mode pauses (without clearing the toggle) in both cases.
  private var liveStreamMode: TimelineMode? {
    guard liveMode, isAuthenticated else { return nil }
    switch timelineViewMode {
    case .all:
      return .all
    case .friends:
      return .friends
    case .me:
      return nil
    }
  }

  private func ingestLiveItem(_ item: TimelineDTO) {
    if let first = items.first, item.id <= first.id {
      return
    }
    withAnimation(.layoutShift) {
      items.insert(item, at: 0)
      // Trimming while a page fetch is in flight would gap the list around its
      // append, so defer to the next event.
      if items.count > timelineLiveItemsCap && !loading {
        items.removeLast(items.count - timelineLiveItemsCap)
        lastID = items.last?.id
        fetched = [:]
        exhausted = false
      }
    }
  }

  var body: some View {
    let rows = items.timelineListRows(lastID: lastID)

    ScrollView {
      VStack {
        if isAuthenticated {
          modePicker
          HStack {
            Text("Hi! \(profile.nickname.withLink(profile.link))")
              .font(.title3)
              .lineLimit(1)
            Spacer()
            if loading, items.count > 0 {
              ProgressView()
            }
            Button {
              showInput = true
            } label: {
              Label("吐槽", systemImage: "square.and.pencil")
                .font(.footnote)
            }
            .adaptiveButtonStyle(.borderedProminent)
            .disabled(showInput)
            .sheet(isPresented: $showInput) {
              TimelineSayView()
            }
          }
        } else {
          AuthView(slogan: "Bangumi 让你的 ACG 生活更美好")
            .frame(height: 100)
        }
      }.padding(8)
      if items.isEmpty {
        if !didFetch {
          if loading {
            TimelineListSkeleton()
          }
        } else {
          ThemedEmptyState(
            systemImage: "clock.arrow.circlepath",
            title: "暂无动态",
            description: "下拉可以刷新时间线")
            .padding(.vertical, 48)
        }
      } else {
        LazyVStack(alignment: .leading) {
          ForEach(rows) { row in
            TimelineItemView(
              item: row.item,
              previousUID: row.previousUID
            )
            .padding(.bottom, 8)
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
          }
        }.padding(.horizontal, 8)
      }
    }
    .onAppear(perform: loadInitialPageIfNeeded)
    .refreshable {
      await reload()
    }
    .onChange(of: timelineViewMode) {
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
    .task(id: liveStreamMode) {
      guard let liveStreamMode else { return }
      // The stream only pushes events created after it connects, so reload first
      // to close the gap since the last fetch.
      await reload()
      do {
        for try await item in TimelineService.liveEvents(mode: liveStreamMode) {
          ingestLiveItem(item)
        }
      } catch is CancellationError {
      } catch {
        Logger.app.error("timeline live stream ended: \(error)")
        liveMode = false
      }
    }
  }

  private var modePicker: some View {
    ScrollView(.horizontal, showsIndicators: false) {
      HStack(spacing: 8) {
        ForEach(TimelineViewMode.allCases, id: \.self) { mode in
          Button {
            withAnimation(.default) {
              timelineViewMode = mode
            }
          } label: {
            Label(mode.desc, systemImage: mode.icon)
          }
          .adaptiveButtonStyle(timelineViewMode == mode ? .borderedProminent : .bordered)
          .controlSize(.small)
        }
        if timelineViewMode != .me {
          Button {
            Haptics.selection()
            withAnimation(.pressSubtle) {
              liveMode.toggle()
            }
          } label: {
            Label("实时", systemImage: "dot.radiowaves.left.and.right")
          }
          .adaptiveButtonStyle(liveMode ? .borderedProminent : .bordered)
          .controlSize(.small)
        }
      }
      .padding(.vertical, 4)
    }
    .scrollClipDisabled()
  }
}
