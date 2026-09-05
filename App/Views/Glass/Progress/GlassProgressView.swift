import OSLog
import SwiftUI

struct GlassProgressView: View {
  @AppStorage("isAuthenticated") var isAuthenticated: Bool = false
  @AppStorage("collectionsUpdatedAt") var collectionsUpdatedAt: Int = 0
  @AppStorage("progressViewMode") var progressViewMode: ProgressViewMode = .tile
  @AppStorage("progressSortMode") var progressSortMode: ProgressSortMode = .collectedAt
  @AppStorage("progressSecondLineMode") var secondLineMode: ProgressSecondLineMode = .info
  @AppStorage("progressTab") var progressTab: SubjectType = .none

  @Environment(\.theme) private var theme

  @State private var refreshing: Bool = true
  @State private var refreshProgress: CGFloat = 0
  @State private var refreshCurrent: Int = 0
  @State private var refreshTotal: Int = 0
  @State private var showRefreshAll: Bool = false
  @State private var showOptions: Bool = false
  @State private var pendingRefreshAll: Bool = false
  @State private var didInitialLoad: Bool = false

  @State private var search: String = ""
  @State private var progressSubjects: [ProgressSubjectDTO] = []
  @State private var counts: [SubjectType: Int] = [:]
  @State private var progressTotal: Int = 0
  @State private var progressOffset: Int = 0
  @State private var progressPageLoading: Bool = false
  @State private var progressLoadGeneration: Int = 0

  @FocusState private var searchFocused: Bool

  private var progressPageLimit: Int {
    switch progressViewMode {
    case .list:
      10
    case .tile:
      20
    }
  }

  private var progressEpisodeWindowSize: Int {
    switch progressViewMode {
    case .list:
      80
    case .tile:
      5
    }
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

  private func refresh(force: Bool = false, showProgress: Bool = true) async {
    let now = Date()
    if force {
      collectionsUpdatedAt = 0
    }
    if showProgress {
      withAnimation(.default) {
        refreshing = true
      }
    }

    do {
      let count = try await refreshCollections(since: collectionsUpdatedAt)
      if count > 0 {
        Notifier.shared.notify(message: "更新了 \(count) 条收藏")
      } else {
        Notifier.shared.notify(message: "没有收藏更新")
      }
      await loadLocalProgress(animate: true)
      collectionsUpdatedAt = Int(now.timeIntervalSince1970)
    } catch {
      Notifier.shared.alert(error: error)
    }
    withAnimation(.default) {
      refreshing = false
    }
  }

  private func refreshCollections(since: Int = 0) async throws -> Int {
    let db = try await AppContext.shared.getDB()
    refreshProgress = 0
    refreshCurrent = 0
    refreshTotal = 0
    let limit: Int = 100
    var offset: Int = 0
    var count: Int = 0
    var loaded: [Int: SubjectType] = [:]
    while true {
      let resp = try await CollectionService.getSubjectCollections(
        since: since, limit: limit, offset: offset)
      if resp.data.isEmpty {
        break
      }
      for item in resp.data {
        try await db.saveSubject(item)
        count += 1
        loaded[item.id] = item.type
        refreshProgress = CGFloat(count) / CGFloat(resp.total)
        refreshCurrent = count
        refreshTotal = resp.total
      }
      await SearchIndexing.index(resp.data.map { $0.searchable() })
      offset += limit
      if offset >= resp.total {
        break
      }
    }
    if since > 0 {
      checkLoadEpisodes(loaded)
    }
    return count
  }

  private func checkLoadEpisodes(_ subjects: [Int: SubjectType]) {
    Task.detached {
      let subjectIds = subjects.filter {
        $0.value == .anime || $0.value == .music || $0.value == .real
      }.map { $0.key }
      for subjectId in subjectIds {
        do {
          try await EpisodeRepository.loadEpisodes(subjectId)
        } catch {
          await Notifier.shared.alert(error: error)
        }
      }
    }
  }

  private var isFirstFullSync: Bool {
    collectionsUpdatedAt == 0 && refreshing
  }

  @ViewBuilder
  private var syncSection: some View {
    if isFirstFullSync {
      VStack(spacing: theme.metrics.listSpacing) {
        GlassSyncBanner(
          progress: Double(refreshProgress),
          current: refreshTotal > 0 ? refreshCurrent : nil,
          total: refreshTotal > 0 ? refreshTotal : nil
        )
        GlassSkeletonCard()
        GlassSkeletonCard(opacity: 0.7)
        GlassSkeletonCard(opacity: 0.4)
      }
      .padding(.horizontal, theme.metrics.screenPadding)
    } else if refreshing {
      HStack(spacing: 8) {
        ProgressView()
        Text("正在同步收藏…")
          .font(.caption)
          .foregroundStyle(theme.tertiaryText)
      }
      .frame(maxWidth: .infinity)
      .padding(.vertical, 6)
    }
  }

  @ViewBuilder
  private var emptySection: some View {
    if collectionsUpdatedAt > 0 {
      if progressPageLoading {
        ProgressView()
          .frame(maxWidth: .infinity)
          .padding()
      } else {
        GlassEmptyCard(
          systemImage: "leaf",
          title: "这个分类下暂时是空的",
          description: "去发现页找点想看的吧"
        )
        .padding(.horizontal, theme.metrics.screenPadding)
      }
    } else {
      GlassEmptyCard(
        systemImage: "cloud",
        title: "还没有同步过收藏",
        description: "下拉即可同步你的 Bangumi 收藏"
      )
      .padding(.horizontal, theme.metrics.screenPadding)
    }
  }

  @ViewBuilder
  private var progressSubjectsView: some View {
    if !progressSubjects.isEmpty {
      switch progressViewMode {
      case .list:
        GlassProgressListSection(
          items: progressSubjects,
          hasMore: hasMoreProgress,
          prefetchWindow: progressPagePrefetchWindow,
          paginationResetToken: progressLoadGeneration,
          loadNextPage: loadNextProgressPage,
          reloadSubject: reloadLoadedProgressSubject
        )
      case .tile:
        GlassProgressGridSection(
          items: progressSubjects,
          hasMore: hasMoreProgress,
          prefetchWindow: progressPagePrefetchWindow,
          paginationResetToken: progressLoadGeneration,
          loadNextPage: loadNextProgressPage,
          reloadSubject: reloadLoadedProgressSubject
        )
      }
    } else if !isFirstFullSync && !refreshing {
      emptySection
    }
  }

  private var authenticatedBody: some View {
    ScrollView {
      LazyVStack(spacing: theme.metrics.listSpacing) {
        GlassSearchField(
          text: $search,
          prompt: "搜索正在看的条目",
          isFocused: $searchFocused
        )
        .padding(.horizontal, theme.metrics.screenPadding)

        GlassTypeChips(selection: $progressTab, counts: counts)

        syncSection
        progressSubjectsView

        if !progressSubjects.isEmpty && !hasMoreProgress {
          GlassProgressFooter()
            .padding(.horizontal, theme.metrics.screenPadding)
        }
      }
      .padding(.top, 4)
      .padding(.bottom, theme.metrics.screenPadding)
    }
    .refreshable {
      UIImpactFeedbackGenerator(style: .medium).impactOccurred()
      await refresh(showProgress: false)
    }
    .navigationTitle("进度管理")
    .navigationBarTitleDisplayMode(.inline)
    .toolbar {
      ToolbarItem(placement: .topBarTrailing) {
        Button {
          showOptions = true
        } label: {
          ToolbarCircle {
            Image(systemName: "ellipsis")
          }
        }
        .buttonStyle(.plain)
      }
    }
    .sheet(
      isPresented: $showOptions,
      onDismiss: {
        if pendingRefreshAll {
          pendingRefreshAll = false
          showRefreshAll = true
        }
      }
    ) {
      GlassOptionsSheet(
        viewMode: $progressViewMode.animated(),
        sortMode: $progressSortMode.animated(),
        secondLineMode: $secondLineMode.animated()
      ) {
        pendingRefreshAll = true
      }
    }
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
    .alert("刷新所有收藏？", isPresented: $showRefreshAll) {
      Button("取消", role: .cancel) {}
      Button("刷新", role: .destructive) {
        Task { await refresh(force: true) }
      }
    } message: {
      Text(refreshAllMessage)
    }
  }

  private var refreshAllMessage: String {
    let total = counts[.none, default: 0]
    if total > 0 {
      return "将清除本地缓存并重新下载全部 \(total) 个条目，可能消耗较多流量。"
    }
    return "将清除本地缓存并重新下载全部收藏，可能消耗较多流量。"
  }

  private var unauthenticatedBody: some View {
    ScrollView {
      GlassLoginCard(
        title: "登录后管理追番进度",
        subtitle: "同步你的收藏，标记每一集，随时接着上次看到的地方。",
        buttonTitle: "登录 / 注册"
      )
      .padding(.horizontal, 24)
      .padding(.top, 60)
    }
    .navigationTitle("进度管理")
    .navigationBarTitleDisplayMode(.inline)
  }

  var body: some View {
    if isAuthenticated {
      authenticatedBody
    } else {
      unauthenticatedBody
    }
  }
}

struct GlassProgressFooter: View {
  @Environment(\.theme) private var theme

  var body: some View {
    HStack(spacing: 12) {
      Rectangle()
        .fill(theme.separator)
        .frame(height: 1)
      Text("没有更多了")
        .font(.caption)
        .foregroundStyle(theme.placeholder)
        .fixedSize()
      Rectangle()
        .fill(theme.separator)
        .frame(height: 1)
    }
    .padding(.vertical, 16)
  }
}

private struct GlassProgressListSection: View {
  let items: [ProgressSubjectDTO]
  let hasMore: Bool
  let prefetchWindow: Int
  let paginationResetToken: Int
  let loadNextPage: () async -> Bool
  let reloadSubject: (Int) async -> Void

  @AppStorage("episodeGridInteractionMode") private var episodeGridInteractionMode:
    EpisodeGridInteractionMode = .menu

  @Environment(\.theme) private var theme

  @State private var prefetchState = NextPagePrefetchState<ProgressSubjectDTO.ID>()

  private func requestNextPage(for trigger: NextPagePrefetchTaskKey<ProgressSubjectDTO.ID>) {
    if let triggerId = prefetchState.request(
      trigger: trigger,
      isLoading: false,
      canLoadMore: hasMore
    ) {
      Task {
        if await loadNextPage() {
          prefetchState.completeLoading(canLoadMore: hasMore)
        } else {
          prefetchState.cancelRequest(triggerId: triggerId)
        }
      }
    }
  }

  var body: some View {
    let nextPageTrigger = items.nextPagePrefetchTrigger(prefetchWindow: prefetchWindow)

    LazyVStack(spacing: theme.metrics.listSpacing) {
      ForEach(items) { item in
        let trigger = NextPagePrefetchTaskKey(
          triggerId: nextPageTrigger.triggerId(for: item.id),
          resetToken: paginationResetToken
        )
        GlassProgressCard(
          payload: ProgressSubjectRenderPayload(item),
          interactionMode: episodeGridInteractionMode,
          reload: {
            await reloadSubject(item.id)
          }
        )
        .task(id: trigger) {
          requestNextPage(for: trigger)
        }
      }
    }
    .padding(.horizontal, theme.metrics.screenPadding)
    .onChange(of: paginationResetToken) { _, _ in
      prefetchState.reset()
    }
  }
}

private struct GlassProgressGridSection: View {
  let items: [ProgressSubjectDTO]
  let hasMore: Bool
  let prefetchWindow: Int
  let paginationResetToken: Int
  let loadNextPage: () async -> Bool
  let reloadSubject: (Int) async -> Void

  @AppStorage("episodeGridInteractionMode") private var episodeGridInteractionMode:
    EpisodeGridInteractionMode = .menu

  @Environment(\.theme) private var theme

  @State private var prefetchState = NextPagePrefetchState<ProgressSubjectDTO.ID>()

  private var columns: [GridItem] {
    Array(repeating: GridItem(.flexible(), spacing: 10, alignment: .top), count: 3)
  }

  private func requestNextPage(for trigger: NextPagePrefetchTaskKey<ProgressSubjectDTO.ID>) {
    if let triggerId = prefetchState.request(
      trigger: trigger,
      isLoading: false,
      canLoadMore: hasMore
    ) {
      Task {
        if await loadNextPage() {
          prefetchState.completeLoading(canLoadMore: hasMore)
        } else {
          prefetchState.cancelRequest(triggerId: triggerId)
        }
      }
    }
  }

  var body: some View {
    let nextPageTrigger = items.nextPagePrefetchTrigger(prefetchWindow: prefetchWindow)

    LazyVGrid(columns: columns, alignment: .leading, spacing: 14) {
      ForEach(items) { item in
        let trigger = NextPagePrefetchTaskKey(
          triggerId: nextPageTrigger.triggerId(for: item.id),
          resetToken: paginationResetToken
        )
        GlassProgressTile(
          payload: ProgressSubjectRenderPayload(item),
          interactionMode: episodeGridInteractionMode,
          reload: {
            await reloadSubject(item.id)
          }
        )
        .task(id: trigger) {
          requestNextPage(for: trigger)
        }
      }
    }
    .padding(.horizontal, theme.metrics.screenPadding)
    .onChange(of: paginationResetToken) { _, _ in
      prefetchState.reset()
    }
  }
}
