import OSLog
import SwiftData
import SwiftUI

struct ChiiProgressView: View {
  @AppStorage("isAuthenticated") var isAuthenticated: Bool = false
  @AppStorage("collectionsUpdatedAt") var collectionsUpdatedAt: Int = 0
  @AppStorage("progressViewMode") var progressViewMode: ProgressViewMode = .tile
  @AppStorage("progressLimit") var progressLimit: Int = 50
  @AppStorage("progressSecondLineMode") var secondLineMode: ProgressSecondLineMode = .info
  @AppStorage("progressTab") var progressTab: SubjectType = .none

  @Environment(\.modelContext) var modelContext

  @State private var refreshing: Bool = false
  @State private var refreshProgress: CGFloat = 0
  @State private var showRefreshAll: Bool = false

  @FocusState private var searching: Bool
  @State private var search: String = ""
  @State private var counts: [SubjectType: Int] = [:]

  var progressLimitIcon: String {
    switch progressLimit {
    case 0:
      return "infinity.circle"
    case 50:
      return "50.circle"
    default:
      return "number.circle"
    }
  }

  func loadCounts() async {
    let doingType = CollectionType.doing.rawValue
    do {
      for type in SubjectType.progressTypes {
        let tvalue = type.rawValue
        let desc = FetchDescriptor<Subject>(
          predicate: #Predicate<Subject> {
            (tvalue == 0 || $0.type == tvalue) && $0.ctype == doingType
          })
        let count = try modelContext.fetchCount(desc)
        counts[type] = count
      }
    } catch {
      Notifier.shared.alert(error: error)
    }
  }

  func refresh(force: Bool = false) async {
    let now = Date()
    if force {
      collectionsUpdatedAt = 0
    }
    do {
      let count = try await refreshCollections(since: collectionsUpdatedAt)
      if count > 0 {
        Notifier.shared.notify(message: "更新了 \(count) 条收藏")
      } else {
        Notifier.shared.notify(message: "没有收藏更新")
      }
    } catch {
      Notifier.shared.alert(error: error)
    }
    collectionsUpdatedAt = Int(now.timeIntervalSince1970)
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
    VStack {
      if isAuthenticated {
        GeometryReader { geometry in
          ScrollView {
            if refreshing {
              if collectionsUpdatedAt == 0 {
                HStack {
                  ProgressView(value: refreshProgress)
                }
                .padding()
                .frame(height: 40)
              } else {
                HStack {
                  Spacer()
                  ProgressView()
                  Spacer()
                }.frame(height: 40)
              }
            }
            Picker("SubjectType", selection: $progressTab) {
              ForEach(SubjectType.progressTypes) { type in
                Text("\(type.description)(\(counts[type, default: 0]))").tag(type)
              }
            }
            .padding(.horizontal, 8)
            .pickerStyle(.segmented)
            .onAppear {
              if !counts.isEmpty {
                return
              }
              Task {
                await loadCounts()
                refreshing = true
                await refresh()
                refreshing = false
                await loadCounts()
              }
            }
            .onChange(of: progressTab) {
              Task {
                await loadCounts()
              }
            }
            if collectionsUpdatedAt > 0 {
              switch progressViewMode {
              case .list:
                ProgressListView(subjectType: progressTab, search: search)
              case .tile:
                ProgressTileView(
                  subjectType: progressTab, search: search, width: geometry.size.width)
              }
            } else {
              if refreshing {
                ProgressView()
                  .padding()
                  .frame(height: 40)
              } else {
                VStack {
                  Spacer()
                  Text("没有收藏数据，请下拉刷新")
                    .font(.title3)
                    .foregroundColor(.secondary)
                  Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
              }
            }
          }
          .searchable(
            text: $search,
            placement: .navigationBarDrawer(displayMode: .always),
            prompt: "搜索正在观看的条目"
          )
          .animation(.default, value: progressTab)
          .animation(.default, value: counts)
          .animation(.default, value: progressLimit)
          .animation(.default, value: progressViewMode)
          .animation(.default, value: secondLineMode)
          .refreshable {
            if refreshing {
              return
            }
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            await refresh()
            await loadCounts()
          }
          .navigationTitle("进度管理")
          .navigationBarTitleDisplayMode(.inline)
          .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
              Menu {
                Picker(selection: $progressViewMode) {
                  ForEach(ProgressViewMode.allCases, id: \.self) { mode in
                    Label(mode.desc, systemImage: mode.icon).tag(mode)
                  }
                } label: {
                  Label("显示模式", systemImage: progressViewMode.icon)
                }
                .pickerStyle(.menu)

                Picker(selection: $secondLineMode) {
                  ForEach(ProgressSecondLineMode.allCases, id: \.self) { mode in
                    Label(mode.desc, systemImage: mode.icon).tag(mode)
                  }
                } label: {
                  Label("第二行内容", systemImage: secondLineMode.icon)
                }
                .pickerStyle(.menu)

                Picker(selection: $progressLimit) {
                  Text("50").tag(50)
                  Text("无限制").tag(0)
                } label: {
                  Label("显示数量", systemImage: progressLimitIcon)
                }
                .pickerStyle(.menu)
                Divider()

                Button("刷新所有收藏", role: .destructive) {
                  showRefreshAll = true
                }
              } label: {
                Image(systemName: "ellipsis.circle")
              }
            }
          }
          .alert("刷新所有收藏", isPresented: $showRefreshAll) {
            Button("取消", role: .cancel) {}
            Button("确定", role: .destructive) {
              Task {
                refreshing = true
                await refresh(force: true)
                refreshing = false
                await loadCounts()
              }
            }
          } message: {
            Text("将从服务器重新下载所有收藏数据，可能需要较长时间")
          }
        }
      } else {
        AuthView(slogan: "使用 Bangumi 管理观看进度")
      }
    }
  }
}
