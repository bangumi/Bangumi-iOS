import CoreSpotlight
import SwiftData
import SwiftUI

struct SettingsView: View {
  @AppStorage("isAuthenticated") var isAuthenticated: Bool = false
  @AppStorage("appearance") var appearance: AppearanceType = .system
  @AppStorage("shareDomain") var shareDomain: ShareDomain = .chii
  @AppStorage("authDomain") var authDomain: AuthDomain = .next
  @AppStorage("subjectImageQuality") var subjectImageQuality: ImageQuality = .high
  @AppStorage("isolationMode") var isolationMode: Bool = false
  @AppStorage("showNSFWBadge") var showNSFWBadge: Bool = true
  @AppStorage("showEpisodeTrends") var showEpisodeTrends: Bool = true
  @AppStorage("hideBlocklist") var hideBlocklist: Bool = false
  @AppStorage("autoCompleteProgress") var autoCompleteProgress: Bool = false
  @AppStorage("enableReactions") var enableReactions: Bool = true
  @AppStorage("enableShakeTitleToggle") var enableShakeTitleToggle: Bool = false
  @AppStorage("replySortOrder") var replySortOrder: ReplySortOrder = .ascending
  @AppStorage("titlePreference") var titlePreference: TitlePreference = .original
  @AppStorage("anonymizeTopicUsers") var anonymizeTopicUsers: Bool = false

  @State private var spotlightRefreshing: Bool = false
  @State private var spotlightProgress: CGFloat = 0
  @State private var logoutConfirm: Bool = false
  @State private var clearDraftsConfirm: Bool = false
  @State private var showEULA: Bool = false

  private var privacyPolicyURL: String {
    let langCode = Locale.current.language.languageCode?.identifier ?? "zh"
    let lang = langCode.hasPrefix("zh") ? "zh" : "en"
    return "https://bangumi.github.io/Bangumi-iOS/privacy/\(lang)/"
  }

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
        Picker(selection: $titlePreference, label: Text("条目标题显示")) {
          ForEach(TitlePreference.allCases, id: \.self) { preference in
            Text(preference.desc).tag(preference)
          }
        }
        Picker(selection: $subjectImageQuality, label: Text("条目封面图片质量")) {
          ForEach(ImageQuality.allCases, id: \.self) { quality in
            Text(quality.desc).tag(quality)
          }
        }
        Picker(selection: $replySortOrder, label: Text("话题回复排序")) {
          ForEach(ReplySortOrder.allCases, id: \.self) { order in
            Text(order.description).tag(order)
          }
        }
      }

      Section(header: Text("超合金")) {
        Toggle(isOn: $isolationMode) {
          Text("单机模式")
        }
        Toggle(isOn: $anonymizeTopicUsers) {
          Text("匿名化讨论")
        }
        Toggle(isOn: $hideBlocklist) {
          Text("屏蔽绝交用户言论")
        }
        Toggle(isOn: $showNSFWBadge) {
          Text("显示 NSFW 标记")
        }
        Toggle(isOn: $enableShakeTitleToggle) {
          Text("摇一摇切换标题显示")
        }
        Toggle(isOn: $showEpisodeTrends) {
          Text("显示章节热度")
        }
        Toggle(isOn: $autoCompleteProgress) {
          Text("标记看过时自动完成所有进度")
        }
        Toggle(isOn: $enableReactions) {
          Text("启用贴贴")
        }
      }

      Section(header: Text("关于")) {
        Button {
          showEULA = true
        } label: {
          Label("社区指导原则", systemImage: "doc.text")
        }
        Link(destination: URL(string: privacyPolicyURL)!) {
          HStack {
            Label("隐私政策", systemImage: "hand.raised")
            Spacer()
            Image(systemName: "arrow.up.right.square")
              .foregroundColor(.secondary)
              .font(.caption)
          }
        }
        Link(
          destination: URL(string: "https://apps.apple.com/app/id6499502714?action=write-review")!
        ) {
          HStack {
            Label("评价此应用", systemImage: "star")
            Spacer()
            Image(systemName: "arrow.up.right.square")
              .foregroundColor(.secondary)
              .font(.caption)
          }
        }
        Link(destination: URL(string: "https://discord.gg/nZPTwzXxAX")!) {
          HStack {
            Label("问题反馈", systemImage: "exclamationmark.bubble")
            Spacer()
            Image(systemName: "arrow.up.right.square")
              .foregroundColor(.secondary)
              .font(.caption)
          }
        }
        Link(destination: URL(string: "https://testflight.apple.com/join/qq79EyFs")!) {
          HStack {
            Label("加入 Beta", systemImage: "sparkles")
            Spacer()
            Image(systemName: "arrow.up.right.square")
              .foregroundColor(.secondary)
              .font(.caption)
          }
        }
        Link(destination: URL(string: "https://github.com/bangumi/Bangumi-iOS")!) {
          HStack {
            Label("查看源码", systemImage: "chevron.left.forwardslash.chevron.right")
            Spacer()
            Image(systemName: "arrow.up.right.square")
              .foregroundColor(.secondary)
              .font(.caption)
          }
        }
        HStack {
          Spacer()
          Text(Chii.shared.version).foregroundStyle(.secondary)
          Spacer()
        }
      }

      if isAuthenticated {
        Section {
          Button(role: .destructive) {
            clearDraftsConfirm = true
          } label: {
            Text("清空草稿箱")
          }
          .alert("清空草稿箱", isPresented: $clearDraftsConfirm) {
            Button("确定", role: .destructive) {
              Task {
                do {
                  let db = try await Chii.shared.getDB()
                  try await db.clearDrafts()
                  Notifier.shared.notify(message: "草稿箱已清空")
                } catch {
                  Notifier.shared.alert(error: error)
                }
              }
            }
          } message: {
            Text("确定要清空所有草稿吗？")
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
    .sheet(isPresented: $showEULA) {
      EULAView(isPresented: $showEULA, showLoginButton: false)
    }
  }
}

#Preview {
  let container = mockContainer()

  return SettingsView()
    .modelContainer(container)
}
