import SwiftUI

struct WikiCreateEntityView: View {
  let kind: WikiEntityKind

  @AppStorage("isAuthenticated") private var isAuthenticated = false
  @AppStorage("profile") private var profile: Profile = Profile()

  private var canCreate: Bool {
    guard isAuthenticated else {
      return false
    }
    switch kind {
    case .subject:
      return profile.canEditSubjectWiki
    case .person, .character:
      return profile.groupEnum.canEditMonoWiki
    case .episode:
      return profile.groupEnum.canEditEpisodeWiki
    }
  }

  var body: some View {
    if canCreate {
      switch kind {
      case .subject:
        SubjectWikiCreateView()
      case .person:
        PersonWikiCreateView()
      case .character:
        CharacterWikiCreateView()
      case .episode:
        Text("请从条目详情页新增章节")
          .foregroundStyle(.secondary)
          .navigationTitle("创建章节")
          .navigationBarTitleDisplayMode(.inline)
      }
    } else {
      List {
        Text("当前账号没有 Wiki 权限")
          .foregroundStyle(.secondary)
      }
      .navigationTitle("创建\(kind.title)")
      .navigationBarTitleDisplayMode(.inline)
    }
  }
}

private struct SubjectWikiCreateView: View {
  @Environment(\.dismiss) private var dismiss

  @State private var type: SubjectType = .anime
  @State private var name = ""
  @State private var platform = 0
  @State private var series = false
  @State private var nsfw = false
  @State private var tagsText = ""
  @State private var summary = ""
  @State private var infobox = ""
  @State private var submitting = false

  private var platforms: [PlatformInfo] {
    SubjectPlatforms.getPlatforms(for: type)
      .values
      .sorted { lhs, rhs in
        if lhs.order == rhs.order {
          return lhs.id < rhs.id
        }
        return lhs.order < rhs.order
      }
  }

  private var saveDisabled: Bool {
    submitting || name.isEmpty || infobox.isEmpty
  }

  private func ensurePlatform() {
    let ids = Set(platforms.map(\.id))
    if !ids.contains(platform) {
      platform = platforms.first?.id ?? 0
    }
  }

  private func submit() async {
    if saveDisabled {
      return
    }
    submitting = true
    defer { submitting = false }
    do {
      let payload = SubjectWikiEditDTO(
        name: name,
        infobox: infobox,
        platform: platform,
        series: type == .book ? series : nil,
        nsfw: nsfw,
        metaTags: wikiTags(from: tagsText),
        summary: summary,
        date: nil
      )
      let subjectId = try await WikiService.createSubject(payload, type: type)
      Notifier.shared.notify(message: "已创建条目 #\(subjectId)")
      dismiss()
    } catch {
      Notifier.shared.alert(error: error)
    }
  }

  var body: some View {
    Form {
      Section("基本信息") {
        Picker("类型", selection: $type) {
          ForEach(SubjectType.allTypes) { item in
            Text(item.description).tag(item)
          }
        }
        .onChange(of: type) {
          ensurePlatform()
        }

        TextField("标题", text: $name)
          .textInputAutocapitalization(.never)

        if !platforms.isEmpty {
          Picker("平台", selection: $platform) {
            ForEach(platforms) { item in
              Text(item.typeCN).tag(item.id)
            }
          }
        }

        if type == .book {
          Toggle("系列条目", isOn: $series)
        }

        Toggle("NSFW", isOn: $nsfw)
        TextField("公共标签", text: $tagsText)
          .textInputAutocapitalization(.never)
      }

      Section("内容") {
        PlaceholderTextEditor(placeholder: "简介", text: $summary, minHeight: 100)
        PlaceholderTextEditor(
          placeholder: "Infobox",
          text: $infobox,
          minHeight: 260,
          monospaced: true
        )
      }
    }
    .formStyle(.grouped)
    .scrollContentBackground(.hidden)
    .navigationTitle("创建条目")
    .navigationBarTitleDisplayMode(.inline)
    .task {
      ensurePlatform()
    }
    .toolbar {
      ToolbarItem(placement: .confirmationAction) {
        Button {
          Task {
            await submit()
          }
        } label: {
          Label("创建", systemImage: "checkmark")
        }
        .disabled(saveDisabled)
      }
    }
  }
}

private struct PersonWikiCreateView: View {
  @Environment(\.dismiss) private var dismiss

  @State private var type: PersonType = .individual
  @State private var name = ""
  @State private var infobox = ""
  @State private var summary = ""
  @State private var profession = PersonProfessionDTO()
  @State private var submitting = false

  private var saveDisabled: Bool {
    submitting || name.isEmpty || infobox.isEmpty
  }

  private func professionBinding(_ career: PersonCareer) -> Binding<Bool> {
    Binding {
      profession[career]
    } set: { value in
      profession[career] = value
    }
  }

  private func submit() async {
    if saveDisabled {
      return
    }
    submitting = true
    defer { submitting = false }
    do {
      let personId = try await WikiService.createPerson(
        name: name,
        type: type,
        infobox: infobox,
        summary: summary,
        profession: profession,
        imageBase64: nil
      )
      Notifier.shared.notify(message: "已创建人物 #\(personId)")
      dismiss()
    } catch {
      Notifier.shared.alert(error: error)
    }
  }

  var body: some View {
    Form {
      Section("基本信息") {
        Picker("类型", selection: $type) {
          ForEach(PersonType.allCases.filter { $0 != .none }) { item in
            Text(item.description).tag(item)
          }
        }
        TextField("姓名", text: $name)
          .textInputAutocapitalization(.never)
      }

      Section("职业") {
        ForEach(PersonCareer.allCases.filter { $0 != .none }, id: \.self) { career in
          Toggle(career.description, isOn: professionBinding(career))
        }
      }

      Section("内容") {
        PlaceholderTextEditor(placeholder: "简介", text: $summary, minHeight: 100)
        PlaceholderTextEditor(
          placeholder: "Infobox",
          text: $infobox,
          minHeight: 260,
          monospaced: true
        )
      }
    }
    .formStyle(.grouped)
    .scrollContentBackground(.hidden)
    .navigationTitle("创建人物")
    .navigationBarTitleDisplayMode(.inline)
    .toolbar {
      ToolbarItem(placement: .confirmationAction) {
        Button {
          Task {
            await submit()
          }
        } label: {
          Label("创建", systemImage: "checkmark")
        }
        .disabled(saveDisabled)
      }
    }
  }
}

private struct CharacterWikiCreateView: View {
  @Environment(\.dismiss) private var dismiss

  @State private var type: CharacterType = .crt
  @State private var name = ""
  @State private var infobox = ""
  @State private var summary = ""
  @State private var submitting = false

  private let supportedTypes: [CharacterType] = [.crt, .mecha, .vessel, .org]

  private var saveDisabled: Bool {
    submitting || name.isEmpty || infobox.isEmpty
  }

  private func submit() async {
    if saveDisabled {
      return
    }
    submitting = true
    defer { submitting = false }
    do {
      let characterId = try await WikiService.createCharacter(
        name: name,
        type: type,
        infobox: infobox,
        summary: summary,
        imageBase64: nil
      )
      Notifier.shared.notify(message: "已创建角色 #\(characterId)")
      dismiss()
    } catch {
      Notifier.shared.alert(error: error)
    }
  }

  var body: some View {
    Form {
      Section("基本信息") {
        Picker("类型", selection: $type) {
          ForEach(supportedTypes) { item in
            Text(item.description).tag(item)
          }
        }
        TextField("名称", text: $name)
          .textInputAutocapitalization(.never)
      }

      Section("内容") {
        PlaceholderTextEditor(placeholder: "简介", text: $summary, minHeight: 100)
        PlaceholderTextEditor(
          placeholder: "Infobox",
          text: $infobox,
          minHeight: 260,
          monospaced: true
        )
      }
    }
    .formStyle(.grouped)
    .scrollContentBackground(.hidden)
    .navigationTitle("创建角色")
    .navigationBarTitleDisplayMode(.inline)
    .toolbar {
      ToolbarItem(placement: .confirmationAction) {
        Button {
          Task {
            await submit()
          }
        } label: {
          Label("创建", systemImage: "checkmark")
        }
        .disabled(saveDisabled)
      }
    }
  }
}
