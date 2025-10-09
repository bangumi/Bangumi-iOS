import CoreSpotlight
import SwiftData
import SwiftUI

struct SettingsView: View {
  @AppStorage("appearance") var appearance: AppearanceType = .system
  @AppStorage("shareDomain") var shareDomain: ShareDomain = .chii
  @AppStorage("authDomain") var authDomain: AuthDomain = .next
  @AppStorage("defaultTab") var defaultTab: ChiiViewTab = .timeline
  @AppStorage("timelineViewMode") var timelineViewMode: TimelineViewMode = .friends
  @AppStorage("progressViewMode") var progressViewMode: ProgressViewMode = .tile
  @AppStorage("progressLimit") var progressLimit: Int = 50
  @AppStorage("progressSortMode") var progressSortMode: ProgressSortMode = .collectedAt
  @AppStorage("isAuthenticated") var isAuthenticated: Bool = false
  @AppStorage("isolationMode") var isolationMode: Bool = false
  @AppStorage("showNSFWBadge") var showNSFWBadge: Bool = true
  @AppStorage("showEpisodeTrends") var showEpisodeTrends: Bool = true
  @AppStorage("hideBlocklist") var hideBlocklist: Bool = false
  @AppStorage("autoCompleteProgress") var autoCompleteProgress: Bool = false
  @AppStorage("subjectImageQuality") var subjectImageQuality: ImageQuality = .high
  @AppStorage("rakuenDefaultMode") var rakuenDefaultMode: GroupTopicFilterMode = .joined
  @AppStorage("subjectCollectsFilterMode") var subjectCollectsFilterMode: FilterMode = .all

  @Environment(\.modelContext) var modelContext

  @State private var spotlightRefreshing: Bool = false
  @State private var spotlightProgress: CGFloat = 0
  @State private var logoutConfirm: Bool = false

  func reindex() {
    spotlightRefreshing = true
    spotlightProgress = 0
    let limit: Int = 50
    var offset: Int = 0
    Task {
      let db = try await Chii.shared.getDB()
      do {
        try await CSSearchableIndex.default().deleteAllSearchableItems()
        Notifier.shared.notify(message: "Spotlight 索引清除成功")
        while true {
          let resp = try await db.getSearchable(
            Subject.self,
            descriptor: FetchDescriptor<Subject>(
              predicate: #Predicate<Subject> {
                $0.ctype != 0
              }
            ),
            limit: limit, offset: offset)
          if resp.data.isEmpty {
            break
          }
          await Chii.shared.index(resp.data)
          spotlightProgress = CGFloat(offset) / CGFloat(resp.total)
          offset += limit
          if offset >= resp.total {
            break
          }
        }
        Notifier.shared.notify(message: "Spotlight 索引重建完成")
        spotlightRefreshing = false
      } catch {
        Notifier.shared.alert(error: error)
      }
    }
  }

  var body: some View {
    Form {
      Section(header: Text("域名")) {
        Picker(selection: $shareDomain, label: Text("分享域名")) {
          ForEach(ShareDomain.allCases, id: \.self) { domain in
            Text(domain.rawValue).tag(domain)
          }
        }
        Picker(selection: $authDomain, label: Text("认证域名")) {
          ForEach(AuthDomain.allCases, id: \.self) { domain in
            Text(domain.rawValue).tag(domain)
          }
        }
      }

      Section(header: Text("显示")) {
        Picker(selection: $appearance, label: Text("主题")) {
          ForEach(AppearanceType.allCases, id: \.self) { appearance in
            Text(appearance.desc).tag(appearance)
          }
        }
        Picker(selection: $defaultTab, label: Text("默认页面")) {
          ForEach(ChiiViewTab.defaultTabs, id: \.self) { tab in
            Text(tab.title).tag(tab)
          }
        }
        Picker(selection: $timelineViewMode, label: Text("默认时间线")) {
          ForEach(TimelineViewMode.allCases, id: \.self) { mode in
            Text(mode.desc).tag(mode)
          }
        }
        Picker(selection: $progressViewMode, label: Text("进度管理模式")) {
          ForEach(ProgressViewMode.allCases, id: \.self) { mode in
            Text(mode.desc).tag(mode)
          }
        }
        Picker(selection: $progressLimit, label: Text("进度管理数量")) {
          Text("50").tag(50)
          Text("100").tag(100)
          Text("无限制").tag(0)
        }
        Picker(selection: $progressSortMode, label: Text("进度管理排序")) {
          ForEach(ProgressSortMode.allCases, id: \.self) { mode in
            Text(mode.desc).tag(mode)
          }
        }
        Picker(selection: $subjectImageQuality, label: Text("条目封面图片质量")) {
          ForEach(ImageQuality.allCases, id: \.self) { quality in
            Text(quality.desc).tag(quality)
          }
        }
        Picker(selection: $rakuenDefaultMode, label: Text("超展开默认显示")) {
          ForEach(GroupTopicFilterMode.allCases, id: \.self) { mode in
            Text(mode.description).tag(mode)
          }
        }
        Picker(selection: $subjectCollectsFilterMode, label: Text("条目收藏用户默认显示")) {
          ForEach(FilterMode.allCases, id: \.self) { mode in
            Text(mode.description).tag(mode)
          }
        }
      }

      Section(header: Text("超合金")) {
        Toggle(isOn: $isolationMode) {
          Text("社恐模式")
        }
        Toggle(isOn: $hideBlocklist) {
          Text("屏蔽绝交用户言论")
        }
        Toggle(isOn: $showNSFWBadge) {
          Text("显示 NSFW 标记")
        }
        Toggle(isOn: $showEpisodeTrends) {
          Text("显示章节热度")
        }
        Toggle(isOn: $autoCompleteProgress) {
          Text("标记看过时自动完成所有进度")
        }
      }

      Section(header: Text("关于")) {
        HStack {
          Text("版本")
          Spacer()
          Text(Chii.shared.version).foregroundStyle(.secondary)
        }
        Link(destination: URL(string: "https://www.everpcpc.com/privacy-policy/chobits/")!) {
          Text("隐私政策")
        }
        Link(destination: URL(string: "https://discord.gg/nZPTwzXxAX")!) {
          Text("问题反馈(Discord)")
        }
        Link(destination: URL(string: "https://github.com/bangumi/Bangumi-iOS")!) {
          Text("查看源码(GitHub)")
        }
      }

      if isAuthenticated {
        Section {
          Button(role: .destructive) {
            do {
              try modelContext.delete(model: Draft.self)
              Notifier.shared.notify(message: "草稿箱已清空")
            } catch {
              Notifier.shared.alert(error: error)
            }
          } label: {
            Text("清空草稿箱")
          }

          if spotlightRefreshing {
            HStack {
              ProgressView(value: spotlightProgress)
            }.frame(height: 20)
          } else {
            Button(role: .destructive) {
              reindex()
            } label: {
              Text("重建 Spotlight 索引")
            }.disabled(spotlightRefreshing)
          }

          Button(role: .destructive) {
            logoutConfirm = true
          } label: {
            Text("退出登录")
          }
          .alert("退出登录", isPresented: $logoutConfirm) {
            Button("确定", role: .destructive) {
              Task {
                await Chii.shared.logout()
              }
            }
          } message: {
            Text("确定要退出登录吗？")
          }
        }
      }
    }
    .navigationTitle("设置")
    .navigationBarTitleDisplayMode(.inline)
  }
}

#Preview {
  let container = mockContainer()

  return SettingsView()
    .modelContainer(container)
}
