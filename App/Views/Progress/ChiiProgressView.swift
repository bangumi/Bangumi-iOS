import SwiftData
import SwiftUI

struct ChiiProgressView: View {
  @AppStorage("isAuthenticated") var isAuthenticated: Bool = false
  @AppStorage("collectionsUpdatedAt") var collectionsUpdatedAt: Int = 0
  @AppStorage("progressViewMode") var progressViewMode: ProgressViewMode = .tile
  @AppStorage("progressSortMode") var progressSortMode: ProgressSortMode = .collectedAt
  @AppStorage("progressSecondLineMode") var secondLineMode: ProgressSecondLineMode = .info
  @AppStorage("progressTab") var progressTab: SubjectType = .none

  @Environment(\.modelContext) var modelContext

  @State private var refreshing: Bool = false
  @State private var refreshProgress: CGFloat = 0
  @State private var showRefreshAll: Bool = false

  @State private var search: String = ""
  @State private var subjectIds: [Int] = []
  @State private var counts: [SubjectType: Int] = [:]

  private func loadCounts() {
    let doingType = CollectionType.doing.rawValue
    for type in SubjectType.progressTypes {
      let tvalue = type.rawValue
      let desc = FetchDescriptor<Subject>(
        predicate: #Predicate<Subject> {
          (tvalue == 0 || $0.type == tvalue) && $0.ctype == doingType
        })
      if let count = try? modelContext.fetchCount(desc) {
        counts[type] = count
      }
    }
  }

  private func updateSubjectIds() {
    let stype = progressTab.rawValue
    let doingType = CollectionType.doing.rawValue
    let descriptor = FetchDescriptor<Subject>(
      predicate: #Predicate<Subject> {
        (stype == 0 || $0.type == stype) && $0.ctype == doingType
          && (search == "" || $0.name.localizedStandardContains(search)
            || $0.alias.localizedStandardContains(search))
      },
      sortBy: [
        SortDescriptor(\.collectedAt, order: .reverse)
      ])

    guard let subjects = try? modelContext.fetch(descriptor) else { return }

    switch progressSortMode {
    case .airTime:
      self.subjectIds = subjects.sorted { subject1, subject2 in
        let days1 = subject1.nextEpisodeDays(context: modelContext)
        let days2 = subject2.nextEpisodeDays(context: modelContext)
        return Subject.compareDays(days1, days2, subject1, subject2)
      }.map(\.subjectId)
    case .collectedAt:
      self.subjectIds = subjects.map(\.subjectId)
    }
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
      collectionsUpdatedAt = Int(now.timeIntervalSince1970)
      updateSubjectIds()
      loadCounts()
    } catch {
      Notifier.shared.notify(message: "更新失败: \(error)")
      Notifier.shared.alert(error: error)
    }
    refreshing = false
  }

  func refreshCollections(since: Int = 0) async throws -> Int {
    let db = try await Chii.shared.getDB()
    refreshProgress = 0
    let limit: Int = 100
    var offset: Int = 0
    var count: Int = 0
    var loaded: [Int: SubjectType] = [:]
    while true {
      let resp = try await Chii.shared.getSubjectCollections(
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
      try await db.commit()
      await Chii.shared.index(resp.data.map { $0.searchable() })
      offset += limit
      if offset >= resp.total {
        break
      }
    }
    try await db.commit()
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
          try await Chii.shared.loadEpisodes(subjectId)
        } catch {
          await Notifier.shared.alert(error: error)
        }
      }
    }
  }

  var body: some View {
    if isAuthenticated {
      ScrollView {
        VStack {
          Picker("SubjectType", selection: $progressTab) {
            ForEach(SubjectType.progressTypes) { type in
              Text("\(type.description)(\(counts[type, default: 0]))").tag(type)
            }
          }
          .padding(.horizontal, 8)
          .pickerStyle(.segmented)

          Group {
            if collectionsUpdatedAt > 0 {
              if progressViewMode == .list {
                ProgressListView(subjectIds: subjectIds)
              } else {
                ProgressTileView(subjectIds: subjectIds)
              }
            } else if refreshing {
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
      }
      .refreshable {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        await refresh(showProgress: false)
      }
      .task {
        guard subjectIds.isEmpty else { return }
        updateSubjectIds()
        loadCounts()
        await refresh()
        updateSubjectIds()
        loadCounts()
      }
      .searchable(
        text: $search,
        placement: .navigationBarDrawer(displayMode: .always),
        prompt: "搜索正在观看的条目"
      )
      .navigationTitle("进度管理")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .topBarTrailing) {
          if refreshing {
            ProgressView()
          } else {
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
              Image(systemName: "ellipsis.circle")
            }.pickerStyle(.menu)
          }
        }
      }
      .onChange(of: progressTab) { updateSubjectIds() }
      .onChange(of: search) { updateSubjectIds() }
      .onChange(of: progressSortMode) { updateSubjectIds() }
      .alert("刷新所有收藏", isPresented: $showRefreshAll) {
        Button("取消", role: .cancel) {}
        Button("确定", role: .destructive) {
          Task { await refresh(force: true) }
        }
      } message: {
        Text("将从服务器重新下载所有收藏数据，可能需要较长时间")
      }
    } else {
      AuthView(slogan: "使用 Bangumi 管理观看进度")
        .navigationTitle("进度管理")
        .navigationBarTitleDisplayMode(.inline)
    }
  }
}
