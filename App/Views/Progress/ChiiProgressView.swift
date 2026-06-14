import OSLog
import SwiftUI

struct ChiiProgressView: View {
  @AppStorage("isAuthenticated") var isAuthenticated: Bool = false
  @AppStorage("collectionsUpdatedAt") var collectionsUpdatedAt: Int = 0
  @AppStorage("progressViewMode") var progressViewMode: ProgressViewMode = .tile
  @AppStorage("progressSortMode") var progressSortMode: ProgressSortMode = .collectedAt
  @AppStorage("progressSecondLineMode") var secondLineMode: ProgressSecondLineMode = .info
  @AppStorage("progressTab") var progressTab: SubjectType = .none

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
    switch progressViewMode {
    case .list:
      7
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
        counts = result
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

  func refresh(force: Bool = false, showProgress: Bool = true) async {
    let now = Date()
    if force {
      collectionsUpdatedAt = 0
    }
    if showProgress {
      refreshing = true
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
      Notifier.shared.notify(message: "更新失败: \(error)")
      Notifier.shared.alert(error: error)
    }
    refreshing = false
  }

  func refreshCollections(since: Int = 0) async throws -> Int {
    let db = try await AppContext.shared.getDB()
    refreshProgress = 0
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

  func checkLoadEpisodes(_ subjects: [Int: SubjectType]) {
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

  func typeDesc(stype: SubjectType) -> String {
    let count = counts[stype, default: 0]
    if count == 0 {
      return stype.description
    } else {
      return "\(stype.description)(\(count))"
    }
  }

  @ViewBuilder
  private var progressSubjectsView: some View {
    if !progressSubjects.isEmpty {
      switch progressViewMode {
      case .list:
        ProgressListView(
          items: progressSubjects,
          isLoadingPage: progressPageLoading,
          hasMore: hasMoreProgress,
          prefetchWindow: progressPagePrefetchWindow,
          paginationResetToken: progressLoadGeneration,
          loadNextPage: loadNextProgressPage,
          reloadSubject: reloadLoadedProgressSubject
        )
      case .tile:
        ProgressTileView(
          items: progressSubjects,
          isLoadingPage: progressPageLoading,
          hasMore: hasMoreProgress,
          prefetchWindow: progressPagePrefetchWindow,
          paginationResetToken: progressLoadGeneration,
          loadNextPage: loadNextProgressPage,
          reloadSubject: reloadLoadedProgressSubject
        )
      }
    } else if collectionsUpdatedAt > 0 {
      if refreshing || progressPageLoading {
        ProgressView()
          .padding()
      } else {
        ContentUnavailableView {
          Label("没有条目", systemImage: "tray")
        } description: {
          Text("当前列表为空，或是搜索无结果")
        }
      }
    } else {
      if refreshing {
        HStack {
          ProgressView(value: refreshProgress)
            .progressViewStyle(.linear)
        }.padding()
      } else {
        ContentUnavailableView {
          Label("没有收藏数据", systemImage: "tray")
        } description: {
          Text("下拉刷新以获取正在观看的条目")
        }
      }
    }
  }

  private var progressTypePicker: some View {
    Picker("SubjectType", selection: $progressTab) {
      ForEach(SubjectType.progressTypes) { type in
        Text(typeDesc(stype: type)).tag(type)
      }
    }
    .padding(.horizontal, 8)
    .pickerStyle(.segmented)
  }

  private var progressOptionsMenu: some View {
    Menu {
      Picker("显示模式", selection: $progressViewMode) {
        ForEach(ProgressViewMode.allCases, id: \.self) { mode in
          Label(mode.desc, systemImage: mode.icon).tag(mode)
        }
      }

      Picker("排序方式", selection: $progressSortMode) {
        ForEach(ProgressSortMode.allCases, id: \.self) { mode in
          Text(mode.desc).tag(mode)
        }
      }

      Picker("副标题内容", selection: $secondLineMode) {
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
      UIImpactFeedbackGenerator(style: .medium).impactOccurred()
      await refresh(showProgress: false)
    }
    .task {
      guard !didInitialLoad else { return }
      didInitialLoad = true
      refreshing = true
      await loadLocalProgress()
      refreshing = false
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

  var body: some View {
    if isAuthenticated {
      authenticatedBody
    } else {
      unauthenticatedBody
    }
  }
}
