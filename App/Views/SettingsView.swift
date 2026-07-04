import CoreSpotlight
import SwiftUI

struct SettingsView: View {
  @AppStorage("isAuthenticated") var isAuthenticated: Bool = false
  @AppStorage("appearance") var appearance: AppearanceType = .system
  @AppStorage("shareDomain") var shareDomain: ShareDomain = .chii
  @AppStorage("authDomain") var authDomain: AuthDomain = .next
  @AppStorage("mirrorRootDomain") var mirrorRootDomain: String = ""
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
  @AppStorage("avatarStyle") var avatarStyle: AvatarStyle = .round
  @AppStorage("episodeGridInteractionMode") var episodeGridInteractionMode:
    EpisodeGridInteractionMode = .menu
  @AppStorage("anonymizeTopicUsers") var anonymizeTopicUsers: Bool = false
  @AppStorage("showSpoilerRelations") var showSpoilerRelations: Bool = false

  @State private var spotlightRefreshing: Bool = false
  @State private var logoutConfirm: Bool = false
  @State private var clearDraftsConfirm: Bool = false
  @State private var showEULA: Bool = false
  @State private var showMirrorDomainSettings: Bool = false
  @State private var appIconController = AppIconController()

  private var privacyPolicyURL: String {
    let langCode = Locale.current.language.languageCode?.identifier ?? "zh"
    let lang = langCode.hasPrefix("zh") ? "zh" : "en"
    return "https://bangumi.github.io/Bangumi-iOS/privacy/\(lang)/"
  }

  private var hasMirrorRootDomain: Bool {
    BangumiURL.normalizedMirrorRootDomain(mirrorRootDomain) != nil
  }

  private var mirrorStatusDescription: String {
    if hasMirrorRootDomain {
      "当前主站：\(BangumiURL.domains.main)"
    } else {
      "留空时使用官方域名"
    }
  }

  private var shareDomainDescription: String {
    "当前：\(BangumiURL.shareHost(for: shareDomain))"
  }

  private var authDomainDescription: String {
    "当前：\(BangumiURL.authHost(for: authDomain))"
  }

  func reindex() {
    spotlightRefreshing = true
    let limit: Int = 50
    var offset: Int = 0
    Task {
      defer {
        spotlightRefreshing = false
      }
      do {
        let db = try await AppContext.shared.getDB()
        try await CSSearchableIndex.default().deleteAllSearchableItems()
        Notifier.shared.notify(message: "Spotlight 索引清除成功")
        while true {
          let resp = try await db.fetchCollectedSubjectSearchable(limit: limit, offset: offset)
          if resp.data.isEmpty {
            break
          }
          await SearchIndexing.index(resp.data)
          offset += limit
          if offset >= resp.total {
            break
          }
        }
        Notifier.shared.notify(message: "Spotlight 索引重建完成")
      } catch {
        Notifier.shared.alert(error: error)
      }
    }
  }

  func clearDrafts() {
    Task {
      do {
        let db = try await AppContext.shared.getDB()
        try await db.clearDrafts()
        Notifier.shared.notify(message: "草稿箱已清空")
      } catch {
        Notifier.shared.alert(error: error)
      }
    }
  }

  private var appIconSelection: Binding<AlternateAppIcon> {
    Binding {
      appIconController.selection
    } set: { icon in
      appIconController.setIcon(icon)
    }
  }

  var body: some View {
    Form {
      // MARK: - 外观
      Section {
        Picker(selection: $appearance) {
          ForEach(AppearanceType.allCases, id: \.self) { appearance in
            Text(appearance.desc).tag(appearance)
          }
        } label: {
          SettingLabel("主题", description: "选择浅色、深色或跟随系统外观")
        }

        Picker(selection: appIconSelection) {
          ForEach(AlternateAppIcon.allCases, id: \.self) { icon in
            Text(icon.title).tag(icon)
          }
        } label: {
          SettingLabel("应用图标", description: "更换应用主屏幕图标")
        }
        .disabled(!appIconController.isAvailable || appIconController.isUpdating)

        Picker(selection: $avatarStyle) {
          ForEach(AvatarStyle.allCases, id: \.self) { style in
            Text(style.desc).tag(style)
          }
        } label: {
          SettingLabel("头像样式", description: "圆形或经典方形头像样式")
        }
      } header: {
        Text("外观")
      }

      // MARK: - 显示
      Section {
        Picker(selection: $titlePreference) {
          ForEach(TitlePreference.allCases, id: \.self) { preference in
            Text(preference.desc).tag(preference)
          }
        } label: {
          SettingLabel("标题显示", description: "在列表和详情页优先显示中文名或原名")
        }

        Picker(selection: $subjectImageQuality) {
          ForEach(ImageQuality.allCases, id: \.self) { quality in
            Text(quality.desc).tag(quality)
          }
        } label: {
          SettingLabel("封面画质", description: "高质量图片更清晰，但消耗更多流量")
        }

        Picker(selection: $replySortOrder) {
          ForEach(ReplySortOrder.allCases, id: \.self) { order in
            Text(order.description).tag(order)
          }
        } label: {
          SettingLabel("回复排序", description: "按发布时间排列话题回复的顺序")
        }

        Toggle(isOn: $showSpoilerRelations) {
          SettingLabel("剧透关联", description: "直接展示被标记为剧透的角色/人物关联，不再模糊遮挡")
        }

        Toggle(isOn: $showNSFWBadge) {
          SettingLabel("NSFW 标记", description: "在标记为 NSFW 的条目封面上显示 R18 角标")
        }

        Toggle(isOn: $showEpisodeTrends) {
          SettingLabel("章节热度", description: "在章节格子底部显示热度指示条")
        }
      } header: {
        Text("显示")
      }

      // MARK: - 交互
      Section {
        Picker(selection: $episodeGridInteractionMode) {
          ForEach(EpisodeGridInteractionMode.allCases, id: \.self) { mode in
            Text(mode.desc).tag(mode)
          }
        } label: {
          SettingLabel("章节菜单", description: "长按或点击章节格子打开操作菜单")
        }

        Toggle(isOn: $enableShakeTitleToggle) {
          SettingLabel("摇一摇切换标题", description: "摇动设备快速切换中文名和原名显示")
        }

        Toggle(isOn: $enableReactions) {
          SettingLabel("启用贴贴", description: "在话题和讨论中启用表情贴贴功能")
        }

        Toggle(isOn: $autoCompleteProgress) {
          SettingLabel("自动完成进度", description: "收藏条目为「看过」时，自动将所有章节标记为完成")
        }
      } header: {
        Text("交互")
      }

      // MARK: - 隐私
      Section {
        Toggle(isOn: $isolationMode) {
          SettingLabel("单机模式", description: "不加载讨论、评论、收藏等社交模块，仅展示条目内容")
        }

        Toggle(isOn: $anonymizeTopicUsers) {
          SettingLabel("匿名讨论", description: "在讨论中隐藏其他用户的头像和昵称，以颜色和哈希值替代")
        }

        Toggle(isOn: $hideBlocklist) {
          SettingLabel("屏蔽绝交用户", description: "隐藏已加入绝交列表用户的发言和评论")
        }
      } header: {
        Text("隐私")
      }

      // MARK: - 网络
      Section {
        Picker(selection: $shareDomain) {
          ForEach(ShareDomain.allCases, id: \.self) { domain in
            Text(domain.title).tag(domain)
          }
        } label: {
          SettingLabel("分享域名", description: "\(shareDomainDescription)")
        }

        Picker(selection: $authDomain) {
          ForEach(AuthDomain.allCases, id: \.self) { domain in
            Text(domain.title).tag(domain)
          }
        } label: {
          SettingLabel("认证域名", description: "\(authDomainDescription)")
        }

        Button {
          showMirrorDomainSettings = true
        } label: {
          HStack {
            SettingLabel("镜像站", description: "\(mirrorStatusDescription)")
            Spacer()
            Image(systemName: "chevron.right")
              .font(.caption)
              .foregroundStyle(.tertiary)
          }
          .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
      } header: {
        Text("网络")
      }

      // MARK: - 关于
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
        Link(destination: URL(string: "https://discord.gg/prAUbRaWwE")!) {
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
        NavigationLink {
          OpenSourceLicensesView()
        } label: {
          Label("开源许可", systemImage: "doc.plaintext")
        }
        HStack {
          Spacer()
          Text(AppMetadata.version).foregroundStyle(.secondary)
          Spacer()
        }
      }
    }
    .contentMargins(.top, 0, for: .scrollContent)
    .navigationTitle("设置")
    .navigationBarTitleDisplayMode(.inline)
    .toolbar {
      if isAuthenticated {
        ToolbarItem(placement: .topBarTrailing) {
          Menu {
            Button(role: .destructive) {
              clearDraftsConfirm = true
            } label: {
              Label("清空草稿箱", systemImage: "trash")
            }

            Button(role: .destructive) {
              reindex()
            } label: {
              Label(
                spotlightRefreshing ? "重建 Spotlight 索引中" : "重建 Spotlight 索引",
                systemImage: spotlightRefreshing ? "hourglass" : "magnifyingglass.circle")
            }
            .disabled(spotlightRefreshing)

            Divider()

            Button(role: .destructive) {
              logoutConfirm = true
            } label: {
              Label("退出登录", systemImage: "rectangle.portrait.and.arrow.right")
            }
          } label: {
            Image(systemName: "ellipsis")
          }
        }
      }
    }
    .sheet(isPresented: $showEULA) {
      EULAView(isPresented: $showEULA, showLoginButton: false)
    }
    .sheet(isPresented: $showMirrorDomainSettings) {
      MirrorDomainSettingsView(mirrorRootDomain: $mirrorRootDomain)
    }
    .alert("清空草稿箱", isPresented: $clearDraftsConfirm) {
      Button("确定", role: .destructive) {
        clearDrafts()
      }
    } message: {
      Text("确定要清空所有草稿吗？")
    }
    .alert("退出登录", isPresented: $logoutConfirm) {
      Button("确定", role: .destructive) {
        Task {
          await AuthService.logout()
        }
      }
    } message: {
      Text("确定要退出登录吗？")
    }
  }
}

private struct MirrorDomainSettingsView: View {
  @Environment(\.dismiss) private var dismiss

  @Binding private var mirrorRootDomain: String
  @State private var draftRootDomain: String
  @FocusState private var isDomainFieldFocused: Bool

  init(mirrorRootDomain: Binding<String>) {
    self._mirrorRootDomain = mirrorRootDomain
    self._draftRootDomain = State(initialValue: mirrorRootDomain.wrappedValue)
  }

  private var trimmedDraftRootDomain: String {
    draftRootDomain.trimmingCharacters(in: .whitespacesAndNewlines)
  }

  private var normalizedDraftRootDomain: String? {
    BangumiURL.normalizedMirrorRootDomain(trimmedDraftRootDomain)
  }

  private var savedMirrorRootDomain: String? {
    BangumiURL.normalizedMirrorRootDomain(mirrorRootDomain)
  }

  private var isDraftEmpty: Bool {
    trimmedDraftRootDomain.isEmpty
  }

  private var isDraftValid: Bool {
    isDraftEmpty || normalizedDraftRootDomain != nil
  }

  private var previewMainHost: String {
    BangumiURL.domains(mirrorRootDomain: normalizedDraftRootDomain).main
  }

  private var previewImageHost: String {
    BangumiURL.domains(mirrorRootDomain: normalizedDraftRootDomain).image
  }

  private var previewNextHost: String {
    BangumiURL.domains(mirrorRootDomain: normalizedDraftRootDomain).next
  }

  var body: some View {
    NavigationStack {
      Form {
        Section {
          TextField("根域名", text: $draftRootDomain, prompt: Text("example.com"))
            .keyboardType(.URL)
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()
            .focused($isDomainFieldFocused)

          if !isDraftValid {
            Text("请输入有效域名，例如 example.com。")
              .font(.caption)
              .foregroundStyle(.red)
          }
        } footer: {
          Text("仅在你信任该镜像站时填写。登录、请求、图片、BBCode 生成链接和镜像分享链接会发送到该站点；使用风险自负。")
        }

        if isDraftValid {
          Section {
            MirrorDomainPreviewRow(title: "主站", host: previewMainHost)
            MirrorDomainPreviewRow(title: "Next/API", host: previewNextHost)
            MirrorDomainPreviewRow(title: "图片", host: previewImageHost)
            MirrorDomainPreviewRow(title: "分享镜像", host: previewMainHost)
          } header: {
            Text("生效域名")
          } footer: {
            Text("分享链接仅在分享域名选择「镜像站」时使用该域名。")
          }
        }

        if savedMirrorRootDomain != nil {
          Section {
            Button("停用镜像站", role: .destructive) {
              mirrorRootDomain = ""
              dismiss()
            }
          }
        }
      }
      .navigationTitle("镜像站")
      .navigationBarTitleDisplayMode(.inline)
      .scrollDismissesKeyboard(.interactively)
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button("取消") {
            dismiss()
          }
        }

        ToolbarItem(placement: .confirmationAction) {
          Button("保存") {
            save()
          }
          .disabled(!isDraftValid)
        }
      }
      .onAppear {
        isDomainFieldFocused = true
      }
    }
  }

  private func save() {
    mirrorRootDomain = normalizedDraftRootDomain ?? ""
    dismiss()
  }
}

private struct MirrorDomainPreviewRow: View {
  let title: String
  let host: String

  var body: some View {
    HStack {
      Text(title)
      Spacer()
      Text(host)
        .foregroundStyle(.secondary)
        .multilineTextAlignment(.trailing)
    }
  }
}
