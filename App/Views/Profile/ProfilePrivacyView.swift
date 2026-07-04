import SwiftUI

struct ProfilePrivacyView: View {
  @State private var privacy: ProfilePrivacyDTO?
  @State private var draftSettings = ProfilePrivacySettingsDTO()
  @State private var showNsfwSubject = false
  @State private var isLoading = false
  @State private var isSaving = false

  private var isBusy: Bool {
    isLoading || isSaving
  }

  private var hasChanges: Bool {
    guard let privacy else {
      return false
    }
    return draftSettings != privacy.settings
      || showNsfwSubject != privacy.preferences.showNsfwSubject
  }

  var body: some View {
    Form {
      if let privacy {
        ProfilePrivacyInteractionSection(
          settings: $draftSettings,
          disabled: isBusy
        )
        ProfilePrivacyNotificationSection(
          settings: $draftSettings,
          disabled: isBusy
        )
        if privacy.preferences.canSetNsfwSubject {
          ProfilePrivacyPreferenceSection(
            preferences: privacy.preferences,
            showNsfwSubject: $showNsfwSubject,
            disabled: isBusy
          )
        }
      } else {
        ProfilePrivacyLoadingSection()
      }
    }
    .disabled(isBusy)
    .navigationTitle("隐私设置")
    .navigationBarTitleDisplayMode(.inline)
    .toolbar {
      ToolbarItem(placement: .topBarTrailing) {
        Button(isSaving ? "保存中" : "保存") {
          Task {
            await save()
          }
        }
        .disabled(!hasChanges || isBusy)
      }
    }
    .refreshable {
      await load()
    }
    .task {
      await load()
    }
  }

  private func load() async {
    if isLoading {
      return
    }
    isLoading = true
    defer {
      isLoading = false
    }

    do {
      let fetched = try await PrivacyService.getProfilePrivacy()
      withAnimation(.default) {
        privacy = fetched
        draftSettings = fetched.settings
        showNsfwSubject = fetched.preferences.showNsfwSubject
      }
    } catch {
      Notifier.shared.alert(error: error)
    }
  }

  private func save() async {
    guard let privacy, hasChanges else {
      return
    }
    isSaving = true
    defer {
      isSaving = false
    }

    do {
      let updated = try await PrivacyService.updateProfilePrivacy(
        settings: draftSettings,
        showNsfwSubject: privacy.preferences.canSetNsfwSubject ? showNsfwSubject : nil
      )
      withAnimation(.default) {
        self.privacy = updated
        draftSettings = updated.settings
        showNsfwSubject = updated.preferences.showNsfwSubject
      }
      Notifier.shared.notify(message: "隐私设置已更新")
    } catch {
      Notifier.shared.alert(error: error)
    }
  }
}

private struct ProfilePrivacyInteractionSection: View {
  @Binding var settings: ProfilePrivacySettingsDTO
  let disabled: Bool

  var body: some View {
    Section {
      ProfilePrivacyValuePicker(
        title: "发送短信",
        description: "谁可以向你发送站内短信",
        selection: $settings.privateMessage,
        values: ProfilePrivacyValue.allCases
      )
      ProfilePrivacyValuePicker(
        title: "回复时间线吐槽",
        description: "谁可以回复你的时间线吐槽",
        selection: $settings.timelineReply,
        values: ProfilePrivacyValue.allCases
      )
      ProfilePrivacyValuePicker(
        title: "回复时间线收藏",
        description: "谁可以回复你的时间线收藏动态",
        selection: $settings.timelineCollectReply,
        values: ProfilePrivacyValue.allCases
      )
      ProfilePrivacyValuePicker(
        title: "加我好友",
        description: "是否允许其他用户向你发送好友请求",
        selection: $settings.follow,
        values: ProfilePrivacyValue.binaryValues
      )
    } header: {
      Text("谁可以")
    }
    .disabled(disabled)
  }
}

private struct ProfilePrivacyNotificationSection: View {
  @Binding var settings: ProfilePrivacySettingsDTO
  let disabled: Bool

  var body: some View {
    Section {
      ProfilePrivacyValuePicker(
        title: "@ 提醒",
        description: "谁的 @ 提醒会发送给你",
        selection: $settings.mentionNotification,
        values: ProfilePrivacyValue.allCases
      )
      ProfilePrivacyValuePicker(
        title: "评论提醒",
        description: "谁的评论回复会发送提醒",
        selection: $settings.commentNotification,
        values: ProfilePrivacyValue.allCases
      )
      ProfilePrivacyValuePicker(
        title: "加好友提醒",
        description: "是否接收好友请求相关提醒",
        selection: $settings.friendNotification,
        values: ProfilePrivacyValue.binaryValues
      )
    } header: {
      Text("提醒")
    }
    .disabled(disabled)
  }
}

private struct ProfilePrivacyPreferenceSection: View {
  let preferences: ProfilePrivacyPreferencesDTO
  @Binding var showNsfwSubject: Bool
  let disabled: Bool

  private var statusText: LocalizedStringKey {
    preferences.allowNsfw ? "已启用" : "未启用"
  }

  var body: some View {
    Section {
      Toggle(isOn: $showNsfwSubject) {
        SettingLabel("显示 NSFW 条目", description: "允许搜索、浏览和推荐展示已标记为 NSFW 的条目")
      }
      .disabled(disabled)

      HStack {
        Text("当前状态")
        Spacer()
        Text(statusText)
          .foregroundStyle(.secondary)
      }

    } header: {
      Text("内容偏好")
    }
  }
}

private struct ProfilePrivacyValuePicker: View {
  let title: LocalizedStringKey
  let description: LocalizedStringKey
  @Binding var selection: ProfilePrivacyValue
  let values: [ProfilePrivacyValue]

  var body: some View {
    Picker(selection: $selection) {
      ForEach(values) { value in
        Text(value.label).tag(value)
      }
    } label: {
      SettingLabel(title, description: description)
    }
  }
}

private struct ProfilePrivacyLoadingSection: View {
  var body: some View {
    Section {
      HStack {
        Spacer()
        ProgressView()
        Spacer()
      }
    }
  }
}

private extension ProfilePrivacyValue {
  var label: LocalizedStringKey {
    switch self {
    case .all:
      return "所有人"
    case .friends:
      return "我的好友"
    case .none:
      return "不接收"
    }
  }
}
