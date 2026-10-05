import OSLog
import SwiftUI

struct ChiiProgressView: View {
  @AppStorage("isAuthenticated") var isAuthenticated: Bool = false
  @AppStorage("profile") var profile: Profile = Profile()
  @AppStorage("collectionsUpdatedAt") var collectionsUpdatedAt: Int = 0
  @AppStorage("progressViewMode") var progressViewMode: ProgressViewMode = .tile
  @AppStorage("progressSortMode") var progressSortMode: ProgressSortMode = .collectedAt
  @AppStorage("progressSecondLineMode") var secondLineMode: ProgressSecondLineMode = .info
  @AppStorage("progressTab") var progressTab: SubjectType = .none

  @Environment(\.theme) private var theme

  @State private var refreshing: Bool = true
  @State private var refreshProgress: CGFloat = 0
  @State private var showRefreshAll: Bool = false
  @State private var didInitialLoad: Bool = false

  @State private var search: String = ""
  @State private var progressSubjects: [ProgressSubjectDTO] = []
  @State private var counts: [SubjectType: Int] = [:]
  @State private var progressTotal: Int = 0
  @State private var progressOffset: Int = 0
  @State private var progressPageLoading: Bool = false
  @State private var progressLoadGeneration: Int = 0

  private var progressPageLimit: Int {
    switch progressViewMode {
    case .list:
      10
    case .tile:
      20
    }
  }

  private var progressEpisodeWindowSize: Int {
    5
  }

  private var progressPagePrefetchWindow: Int {
    switch progressViewMode {
    case .list:
      5
    case .tile:
      10
    }
  }

  private var hasMoreProgress: Bool {
    progressOffset < progressTotal
  }

  private func applyProgressSubjects(
    _ updatedSubjects: [ProgressSubjectDTO],
    total: Int,
    animate: Bool = false
  ) {
    let updatedOffset = min(updatedSubjects.count, total)

    let update = {
      progressSubjects = updatedSubjects
      progressTotal = total
      progressOffset = updatedOffset
    }
    if animate {
      withAnimation {
        update()
      }
    } else {
      var transaction = Transaction()
      transaction.disablesAnimations = true
      withTransaction(transaction) {
        update()
      }
    }
  }

  private func removeProgressSubject(_ subjectId: Int) {
    let updatedSubjects = progressSubjects.filter { $0.id != subjectId }
    let removedCount = progressSubjects.count - updatedSubjects.count
    guard removedCount > 0 else {
      return
    }

    let updatedTotal = max(updatedSubjects.count, progressTotal - removedCount)
    withAnimation {
      progressSubjects = updatedSubjects
      progressTotal = updatedTotal
      progressOffset = min(updatedSubjects.count, updatedTotal)
    }
  }

  private func mergeProgressSubject(_ item: ProgressSubjectDTO) {
    let updatedSubjects = progressSubjects.mergedById(with: [item])

    withAnimation {
      progressSubjects = updatedSubjects
      progressOffset = min(updatedSubjects.count, progressTotal)
    }
  }

  private func loadCounts() async {
    do {
      let db = try await AppContext.shared.getDB()
      let result = try await db.fetchProgressCounts()
      if counts != result {
        withAnimation(.default) {
          counts = result
        }
      }
    } catch {
      Logger.app.error("Failed to load counts: \(error)")
    }
  }

  private func loadProgressPage(
    reset: Bool,
    generation: Int,
    animateReset: Bool = false
  ) async -> Bool {
    if !reset {
      guard !progressPageLoading, hasMoreProgress else {
        return false
      }
    }
    progressPageLoading = true
    defer {
      if generation == progressLoadGeneration {
        progressPageLoading = false
      }
    }
    do {
      let db = try await AppContext.shared.getDB()
      let pageOffset = reset ? 0 : progressOffset
      let result = try await db.fetchProgressSubjects(
        progressTab: progressTab,
        progressSortMode: progressSortMode,
        search: search,
        episodeWindowSize: progressEpisodeWindowSize,
        limit: progressPageLimit,
        offset: pageOffset
      )
      guard generation == progressLoadGeneration else {
        return true
      }
      if reset {
        applyProgressSubjects(result.data, total: result.total, animate: animateReset)
      } else {
        let updatedSubjects = progressSubjects.mergedById(with: result.data)
        applyProgressSubjects(updatedSubjects, total: result.total)
      }
    } catch {
      Logger.app.error("Failed to load progress page: \(error)")
      Notifier.shared.alert(error: error)
    }
    return true
  }

  private func reloadProgressPages(animate: Bool = false) async {
    progressLoadGeneration += 1
    let generation = progressLoadGeneration
    _ = await loadProgressPage(reset: true, generation: generation, animateReset: animate)
  }

  private func loadNextProgressPage() async -> Bool {
    await loadProgressPage(reset: false, generation: progressLoadGeneration)
  }

  private func reloadLoadedProgressWindow(
    generation: Int,
    progressTab: SubjectType,
    progressSortMode: ProgressSortMode,
    progressViewMode: ProgressViewMode,
    search: String,
    episodeWindowSize: Int,
    limit: Int
  ) async throws {
    let db = try await AppContext.shared.getDB()
    let result = try await db.fetchProgressSubjects(
      progressTab: progressTab,
      progressSortMode: progressSortMode,
      search: search,
      episodeWindowSize: episodeWindowSize,
      limit: max(limit, progressPageLimit),
      offset: 0
    )
    guard generation == progressLoadGeneration,
      progressTab == self.progressTab,
      progressSortMode == self.progressSortMode,
      progressViewMode == self.progressViewMode,
      search == self.search
    else {
      return
    }
    applyProgressSubjects(result.data, total: result.total)
  }

  private func reloadProgressSubject(
    _ subjectId: Int,
    mayChangeProgressMembership: Bool = false
  ) async {
    let generation = progressLoadGeneration
    let progressTabSnapshot = progressTab
    let progressSortModeSnapshot = progressSortMode
    let progressViewModeSnapshot = progressViewMode
    let searchSnapshot = search
    let episodeWindowSizeSnapshot = progressEpisodeWindowSize

    do {
      let db = try await AppContext.shared.getDB()
      let item = try await db.fetchProgressSubject(
        subjectId: subjectId,
        progressTab: progressTabSnapshot,
        search: searchSnapshot,
        episodeWindowSize: episodeWindowSizeSnapshot
      )
      guard generation == progressLoadGeneration,
        progressTabSnapshot == progressTab,
        progressSortModeSnapshot == progressSortMode,
        progressViewModeSnapshot == progressViewMode,
        searchSnapshot == search
      else {
        return
      }
      let isLoaded = progressSubjects.contains(where: { $0.id == subjectId })
      guard isLoaded || mayChangeProgressMembership else {
        return
      }

      guard isLoaded else {
        try await reloadLoadedProgressWindow(
          generation: generation,
          progressTab: progressTabSnapshot,
          progressSortMode: progressSortModeSnapshot,
          progressViewMode: progressViewModeSnapshot,
          search: searchSnapshot,
          episodeWindowSize: episodeWindowSizeSnapshot,
          limit: progressSubjects.count
        )
        await loadCounts()
        return
      }

      guard let item else {
        removeProgressSubject(subjectId)
        if mayChangeProgressMembership {
          await loadCounts()
        }
        return
      }
      if progressSortModeSnapshot == .airTime {
        try await reloadLoadedProgressWindow(
          generation: generation,
          progressTab: progressTabSnapshot,
          progressSortMode: progressSortModeSnapshot,
          progressViewMode: progressViewModeSnapshot,
          search: searchSnapshot,
          episodeWindowSize: episodeWindowSizeSnapshot,
          limit: progressSubjects.count
        )
        if mayChangeProgressMembership {
          await loadCounts()
        }
        return
      }
      mergeProgressSubject(item)
      if mayChangeProgressMembership {
        await loadCounts()
      }
    } catch {
      Logger.app.error("Failed to reload progress subject: \(error)")
      Notifier.shared.alert(error: error)
    }
  }

  private func reloadLoadedProgressSubject(_ subjectId: Int) async {
    await reloadProgressSubject(subjectId)
  }

  private func handleProgressSubjectInvalidation(_ notification: Notification) {
    guard let subjectId = ProgressSubjectInvalidation.subjectId(from: notification) else {
      return
    }
    let mayChangeProgressMembership =
      ProgressSubjectInvalidation.mayChangeProgressMembership(from: notification)
    guard mayChangeProgressMembership || progressSubjects.contains(where: { $0.id == subjectId })
    else {
      return
    }
    Task {
      await ProgressSubjectInvalidationStore.shared.takeSubjectId(subjectId)
      await reloadProgressSubject(
        subjectId,
        mayChangeProgressMembership: mayChangeProgressMembership
      )
    }
  }

  private func reloadPendingProgressSubjects() async {
    let loadedSubjectIds = Set(progressSubjects.map(\.id))
    let invalidations = await ProgressSubjectInvalidationStore.shared.takePendingInvalidations(
      loadedSubjectIds: loadedSubjectIds
    )
    for invalidation in invalidations {
      await reloadProgressSubject(
        invalidation.subjectId,
        mayChangeProgressMembership: invalidation.mayChangeProgressMembership
      )
    }
  }

  private func loadLocalProgress(animate: Bool = false) async {
    await reloadProgressPages(animate: animate)
    await loadCounts()
  }

  private func loadInitialProgressIfNeeded() {
    guard !didInitialLoad else { return }
    didInitialLoad = true
    withAnimation(.default) {
      refreshing = true
    }
    Task {
      await loadLocalProgress()
      withAnimation(.default) {
        refreshing = false
      }
      await refresh(showProgress: false)
    }
  }

  func refresh(force: Bool = false, showProgress: Bool = true) async {
    if force {
      collectionsUpdatedAt = 0
    }
    if showProgress {
      withAnimation(.default) {
        refreshing = true
      }
    }

    do {
      refreshProgress = 0
      let since = collectionsUpdatedAt
      let (loaded, maxUpdatedAt) = try await CollectionRepository.refreshCollections(since: since) {
        count, total in
        refreshProgress = CGFloat(count) / CGFloat(total)
      }
      if since > 0 {
        CollectionRepository.checkLoadEpisodes(loaded)
      }
      if loaded.count > 0 {
        Notifier.shared.notify(message: "更新了 \(loaded.count) 条收藏")
      } else {
        Notifier.shared.notify(message: "没有收藏更新")
      }
      await loadLocalProgress(animate: true)
      AppConfig.advanceCollectionsWatermark(maxUpdatedAt)
    } catch {
      Notifier.shared.alert(error: error)
    }
    withAnimation(.default) {
      refreshing = false
    }
  }

  @ViewBuilder
  private var progressSubjectsView: some View {
    if !progressSubjects.isEmpty {
      switch progressViewMode {
      case .list:
        ProgressListView(
          items: progressSubjects,
          hasMore: hasMoreProgress,
          prefetchWindow: progressPagePrefetchWindow,
          paginationResetToken: progressLoadGeneration,
          loadNextPage: loadNextProgressPage,
          reloadSubject: reloadLoadedProgressSubject
        )
      case .tile:
        ProgressTileView(
          items: progressSubjects,
          hasMore: hasMoreProgress,
          prefetchWindow: progressPagePrefetchWindow,
          paginationResetToken: progressLoadGeneration,
          loadNextPage: loadNextProgressPage,
          reloadSubject: reloadLoadedProgressSubject
        )
      }
    } else if collectionsUpdatedAt > 0 {
      if refreshing || progressPageLoading {
        ProgressSubjectsSkeleton(mode: progressViewMode)
      } else if !search.isEmpty {
        ThemedEmptyState(
          systemImage: "magnifyingglass",
          title: "没有找到相关条目",
          description: "换个关键字再试试")
      } else {
        ThemedEmptyState(
          systemImage: "tray",
          title: "这个分类下暂时是空的",
          description: "去发现页找点想看的吧")
      }
    } else {
      if refreshing {
        HStack {
          ProgressView(value: refreshProgress)
            .progressViewStyle(.linear)
        }.padding()
      } else {
        ThemedEmptyState(
          systemImage: "cloud",
          title: "还没有同步过收藏",
          description: "同步后即可管理你的观看进度",
          primary: .init(title: "立即同步") {
            Task { await refresh() }
          })
      }
    }
  }

  private func progressTabIcon(_ type: SubjectType) -> String {
    switch type {
    case .none:
      return "square.grid.2x2"
    default:
      return type.icon
    }
  }

  private var progressTypePicker: some View {
    ScrollView(.horizontal, showsIndicators: false) {
      HStack(spacing: 8) {
        ForEach(SubjectType.progressTypes) { type in
          Button {
            withAnimation(.default) {
              progressTab = type
            }
          } label: {
            HStack(spacing: 4) {
              Image(systemName: progressTabIcon(type))
              Text(type.description)
              let count = counts[type, default: 0]
              if count > 0 {
                Text("\(count)")
                  .monospacedDigit()
                  .contentTransition(.numericText())
                  .animation(.contentSwap, value: count)
                  .foregroundStyle(
                    progressTab == type
                      ? AnyShapeStyle(.white.opacity(0.8)) : AnyShapeStyle(.secondary))
              }
            }
          }
          .adaptiveButtonStyle(progressTab == type ? .borderedProminent : .bordered)
          .controlSize(.small)
        }
      }
      .padding(.horizontal, 8)
      .padding(.vertical, 4)
    }
    .scrollClipDisabled()
  }

  private var progressOptionsMenu: some View {
    Menu {
      Picker("显示模式", selection: $progressViewMode.animated()) {
        ForEach(ProgressViewMode.allCases, id: \.self) { mode in
          Label(mode.desc, systemImage: mode.icon).tag(mode)
        }
      }

      Picker("排序方式", selection: $progressSortMode.animated()) {
        ForEach(ProgressSortMode.allCases, id: \.self) { mode in
          Text(mode.desc).tag(mode)
        }
      }

      Picker("副标题内容", selection: $secondLineMode.animated()) {
        ForEach(ProgressSecondLineMode.allCases, id: \.self) { mode in
          Label(mode.desc, systemImage: mode.icon).tag(mode)
        }
      }

      Divider()

      Button("刷新所有收藏", role: .destructive) {
        showRefreshAll = true
      }
    } label: {
      Image(systemName: "ellipsis")
    }
    .pickerStyle(.menu)
  }

  @ViewBuilder
  private var progressToolbarContent: some View {
    if refreshing {
      ProgressView()
    } else {
      progressOptionsMenu
    }
  }

  @ToolbarContentBuilder
  private var progressToolbar: some ToolbarContent {
    ToolbarItemGroup(placement: .topBarLeading) {
      if isAuthenticated {
        NavigationLink(value: NavDestination.profileHome) {
          ProfileToolbarAvatarView(imageURL: profile.avatar?.large)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("我的")
      }
    }
    ToolbarItem(placement: .topBarTrailing) {
      progressToolbarContent
    }
  }

  private var authenticatedBody: some View {
    ScrollView {
      VStack {
        progressTypePicker
        progressSubjectsView
      }
    }
    .refreshable {
      Haptics.impact()
      await refresh(showProgress: false)
    }
    .searchable(
      text: $search,
      placement: .navigationBarDrawer(displayMode: .always),
      prompt: "搜索正在观看的条目"
    )
    .searchInputTraits()
    .navigationTitle("进度管理")
    .navigationBarTitleDisplayMode(.inline)
    .toolbar { progressToolbar }
    .onChange(of: progressTab) { Task { await reloadProgressPages(animate: true) } }
    .onChange(of: search) { Task { await reloadProgressPages(animate: true) } }
    .onChange(of: progressSortMode) { Task { await reloadProgressPages(animate: true) } }
    .onChange(of: progressViewMode) { Task { await reloadProgressPages(animate: true) } }
    .onReceive(
      NotificationCenter.default.publisher(for: ProgressSubjectInvalidation.notificationName),
      perform: handleProgressSubjectInvalidation
    )
    .onAppear {
      loadInitialProgressIfNeeded()
      Task {
        await reloadPendingProgressSubjects()
      }
    }
    .alert("刷新所有收藏", isPresented: $showRefreshAll) {
      Button("取消", role: .cancel) {}
      Button("确定", role: .destructive) {
        Task { await refresh(force: true) }
      }
    } message: {
      Text("将从服务器重新下载所有收藏数据，可能需要较长时间")
    }
  }

  private var unauthenticatedBody: some View {
    AuthView(slogan: "使用 Bangumi 管理观看进度")
      .navigationTitle("进度管理")
      .navigationBarTitleDisplayMode(.inline)
  }

  @ViewBuilder
  private var classicBody: some View {
    if isAuthenticated {
      authenticatedBody
    } else {
      unauthenticatedBody
    }
  }

  @ViewBuilder
  var body: some View {
    if theme.isClassic {
      classicBody
    } else {
      GlassProgressView()
    }
  }
}
