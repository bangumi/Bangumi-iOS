import SwiftUI

private enum SubjectWikiUpdateMode: String, CaseIterable, Identifiable {
  case full
  case partial

  var id: Self {
    self
  }

  var title: String {
    switch self {
    case .full:
      return "完整保存"
    case .partial:
      return "增量保存"
    }
  }
}

private enum EpisodeWikiBatchMode: String, CaseIterable, Identifiable {
  case create
  case edit

  var id: Self {
    self
  }

  var title: String {
    switch self {
    case .create:
      return "新增章节"
    case .edit:
      return "批量编辑"
    }
  }
}

func wikiTags(from text: String) -> [String] {
  text
    .split(whereSeparator: { $0.isWhitespace || $0 == "," || $0 == "，" })
    .map(String.init)
}

private func optionalWikiText(_ text: String) -> String? {
  let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
  return trimmed.isEmpty ? nil : trimmed
}

private func wikiDouble(from text: String) -> Double? {
  Double(text.trimmingCharacters(in: .whitespacesAndNewlines))
}

private func hasInvalidOptionalWikiDouble(_ text: String) -> Bool {
  let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
  return !trimmed.isEmpty && Double(trimmed) == nil
}

private func episodeDisc(from text: String, preservingEmpty: Bool) -> Double? {
  let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
  if trimmed.isEmpty {
    return preservingEmpty ? 0 : nil
  }
  guard let disc = Double(trimmed) else {
    return nil
  }
  return disc
}

private func omitUnchangedEpisodePatchFields(
  _ payload: inout EpisodeWikiEditDTO,
  original: EpisodeWikiInfoDTO,
  discText: String,
  dateText: String
) {
  if payload.ep == original.ep {
    payload.ep = nil
  }
  let trimmedDiscText = discText.trimmingCharacters(in: .whitespacesAndNewlines)
  if payload.disc == original.disc || (trimmedDiscText.isEmpty && original.disc == nil) {
    payload.disc = nil
  }
  if payload.type == original.type {
    payload.type = nil
  }
  let trimmedDateText = dateText.trimmingCharacters(in: .whitespacesAndNewlines)
  if trimmedDateText.isEmpty || payload.date == original.date {
    payload.date = nil
  }
}

struct SubjectWikiEditSheet: View {
  @Environment(\.dismiss) private var dismiss

  let subjectId: Int
  let onSave: () -> Void

  @State private var info: SubjectWikiInfoDTO?
  @State private var edit = SubjectWikiEditDTO(
    name: "",
    infobox: "",
    platform: 0,
    series: nil,
    nsfw: false,
    metaTags: [],
    summary: "",
    date: nil
  )
  @State private var tagsText = ""
  @State private var commitMessage = ""
  @State private var mode: SubjectWikiUpdateMode = .full
  @State private var loading = false
  @State private var submitting = false

  private var saveDisabled: Bool {
    guard let info else {
      return true
    }
    if submitting || edit.name.isEmpty || commitMessage.isEmpty {
      return true
    }
    switch mode {
    case .full:
      return edit.infobox.isEmpty
    case .partial:
      return edit.infobox.isEmpty && !info.infobox.isEmpty
    }
  }

  private func load() async {
    if info != nil || loading {
      return
    }
    loading = true
    defer { loading = false }
    do {
      let fetched = try await WikiService.getSubjectWikiInfo(subjectId)
      info = fetched
      edit = fetched.edit
      tagsText = fetched.metaTags.joined(separator: " ")
    } catch {
      Notifier.shared.alert(error: error)
    }
  }

  private func payload() -> SubjectWikiEditDTO {
    let currentTags = wikiTags(from: tagsText)
    return SubjectWikiEditDTO(
      name: edit.name,
      infobox: edit.infobox,
      platform: edit.platform,
      series: edit.series,
      nsfw: edit.nsfw,
      metaTags: currentTags,
      summary: edit.summary,
      date: edit.date
    )
  }

  private func submit() async {
    guard let info, !saveDisabled else {
      return
    }
    submitting = true
    defer { submitting = false }
    do {
      let payload = payload()
      if mode == .full {
        try await WikiService.updateSubjectWikiInfo(
          subjectId: subjectId,
          subject: payload,
          expectedRevision: info.expectedRevision,
          commitMessage: commitMessage
        )
      } else {
        try await WikiService.patchSubjectWikiInfo(
          subjectId: subjectId,
          subject: payload,
          expectedRevision: info.expectedRevision,
          commitMessage: commitMessage,
          originalInfo: info
        )
      }
      _ = try? await SubjectRepository.loadSubject(subjectId)
      Notifier.shared.notify(message: "条目 Wiki 已保存")
      onSave()
      dismiss()
    } catch {
      Notifier.shared.alert(error: error)
    }
  }

  var body: some View {
    SheetView(title: "编辑条目 Wiki", closeDisabled: submitting, applyFormStyle: true) {
      Form {
        if loading {
          ProgressView()
        }

        Section("基本信息") {
          TextField("标题", text: $edit.name)
            .textInputAutocapitalization(.never)

          Picker("平台", selection: $edit.platform) {
            if let info, !info.availablePlatform.isEmpty {
              ForEach(info.availablePlatform) { platform in
                Text(platform.text).tag(platform.id)
              }
            } else {
              Text("默认").tag(0)
            }
          }

          if info?.typeID == .book {
            Toggle("系列条目", isOn: Binding(
              get: { edit.series ?? false },
              set: { edit.series = $0 }
            ))
          }

          Toggle("NSFW", isOn: $edit.nsfw)
          TextField("公共标签", text: $tagsText)
            .textInputAutocapitalization(.never)
        }

        Section("内容") {
          PlaceholderTextEditor(placeholder: "简介", text: $edit.summary, minHeight: 100)
          PlaceholderTextEditor(
            placeholder: "Infobox",
            text: $edit.infobox,
            minHeight: 220,
            monospaced: true
          )
        }

        Section("提交") {
          Picker("保存方式", selection: $mode) {
            ForEach(SubjectWikiUpdateMode.allCases) { item in
              Text(item.title).tag(item)
            }
          }
          TextField("编辑摘要", text: $commitMessage)
            .textInputAutocapitalization(.never)
        }
      }
      .task {
        await load()
      }
    } controls: {
      Button {
        Task {
          await submit()
        }
      } label: {
        Label("保存", systemImage: "checkmark")
      }
      .disabled(saveDisabled)
    }
  }
}

struct PersonWikiEditSheet: View {
  @Environment(\.dismiss) private var dismiss

  let personId: Int
  let onSave: () -> Void

  @State private var info: PersonWikiInfoDTO?
  @State private var edit = PersonWikiEditDTO(
    name: "",
    infobox: "",
    summary: "",
    profession: PersonProfessionDTO()
  )
  @State private var commitMessage = ""
  @State private var loading = false
  @State private var submitting = false

  private var saveDisabled: Bool {
    guard let info else {
      return true
    }
    return submitting
      || edit.name.isEmpty
      || (edit.infobox.isEmpty && !info.infobox.isEmpty)
      || commitMessage.isEmpty
  }

  private func professionBinding(_ career: PersonCareer) -> Binding<Bool> {
    Binding {
      edit.profession[career]
    } set: { value in
      edit.profession[career] = value
    }
  }

  private func load() async {
    if info != nil || loading {
      return
    }
    loading = true
    defer { loading = false }
    do {
      let fetched = try await WikiService.getPersonWikiInfo(personId)
      info = fetched
      edit = fetched.edit
    } catch {
      Notifier.shared.alert(error: error)
    }
  }

  private func submit() async {
    if saveDisabled {
      return
    }
    guard let info else {
      return
    }
    submitting = true
    defer { submitting = false }
    do {
      try await WikiService.patchPersonWikiInfo(
        personId: personId,
        person: edit,
        originalProfession: info.profession,
        expectedRevision: info.expectedRevision,
        commitMessage: commitMessage
      )
      try? await PersonRepository.loadPerson(personId)
      Notifier.shared.notify(message: "人物 Wiki 已保存")
      onSave()
      dismiss()
    } catch {
      Notifier.shared.alert(error: error)
    }
  }

  var body: some View {
    SheetView(title: "编辑人物 Wiki", closeDisabled: submitting, applyFormStyle: true) {
      Form {
        if loading {
          ProgressView()
        }

        Section("基本信息") {
          TextField("姓名", text: $edit.name)
            .textInputAutocapitalization(.never)
        }

        Section("职业") {
          ForEach(PersonCareer.allCases.filter { $0 != .none }, id: \.self) { career in
            Toggle(career.description, isOn: professionBinding(career))
          }
        }

        Section("内容") {
          PlaceholderTextEditor(placeholder: "简介", text: $edit.summary, minHeight: 100)
          PlaceholderTextEditor(
            placeholder: "Infobox",
            text: $edit.infobox,
            minHeight: 220,
            monospaced: true
          )
        }

        Section("提交") {
          TextField("编辑摘要", text: $commitMessage)
            .textInputAutocapitalization(.never)
        }
      }
      .task {
        await load()
      }
    } controls: {
      Button {
        Task {
          await submit()
        }
      } label: {
        Label("保存", systemImage: "checkmark")
      }
      .disabled(saveDisabled)
    }
  }
}

struct CharacterWikiEditSheet: View {
  @Environment(\.dismiss) private var dismiss

  let characterId: Int
  let onSave: () -> Void

  @State private var info: CharacterWikiInfoDTO?
  @State private var edit = CharacterWikiEditDTO(name: "", infobox: "", summary: "")
  @State private var commitMessage = ""
  @State private var loading = false
  @State private var submitting = false

  private var saveDisabled: Bool {
    guard let info else {
      return true
    }
    return submitting
      || edit.name.isEmpty
      || (edit.infobox.isEmpty && !info.infobox.isEmpty)
      || commitMessage.isEmpty
  }

  private func load() async {
    if info != nil || loading {
      return
    }
    loading = true
    defer { loading = false }
    do {
      let fetched = try await WikiService.getCharacterWikiInfo(characterId)
      info = fetched
      edit = fetched.edit
    } catch {
      Notifier.shared.alert(error: error)
    }
  }

  private func submit() async {
    if saveDisabled {
      return
    }
    submitting = true
    defer { submitting = false }
    do {
      try await WikiService.patchCharacterWikiInfo(
        characterId: characterId,
        character: edit,
        expectedRevision: info?.expectedRevision,
        commitMessage: commitMessage
      )
      try? await CharacterRepository.loadCharacter(characterId)
      Notifier.shared.notify(message: "角色 Wiki 已保存")
      onSave()
      dismiss()
    } catch {
      Notifier.shared.alert(error: error)
    }
  }

  var body: some View {
    SheetView(title: "编辑角色 Wiki", closeDisabled: submitting, applyFormStyle: true) {
      Form {
        if loading {
          ProgressView()
        }

        Section("基本信息") {
          TextField("名称", text: $edit.name)
            .textInputAutocapitalization(.never)
        }

        Section("内容") {
          PlaceholderTextEditor(placeholder: "简介", text: $edit.summary, minHeight: 100)
          PlaceholderTextEditor(
            placeholder: "Infobox",
            text: $edit.infobox,
            minHeight: 220,
            monospaced: true
          )
        }

        Section("提交") {
          TextField("编辑摘要", text: $commitMessage)
            .textInputAutocapitalization(.never)
        }
      }
      .task {
        await load()
      }
    } controls: {
      Button {
        Task {
          await submit()
        }
      } label: {
        Label("保存", systemImage: "checkmark")
      }
      .disabled(saveDisabled)
    }
  }
}

struct EpisodeWikiEditSheet: View {
  @Environment(\.dismiss) private var dismiss

  let episodeId: Int
  let onSave: () -> Void

  @State private var info: EpisodeWikiInfoDTO?
  @State private var name = ""
  @State private var nameCN = ""
  @State private var epText = ""
  @State private var discText = ""
  @State private var date = ""
  @State private var type: EpisodeType = .main
  @State private var duration = ""
  @State private var summary = ""
  @State private var commitMessage = ""
  @State private var loading = false
  @State private var submitting = false

  private var saveDisabled: Bool {
    submitting || info == nil || epText.isEmpty || wikiDouble(from: epText) == nil
      || hasInvalidOptionalWikiDouble(discText)
      || commitMessage.isEmpty
  }

  private func load() async {
    if info != nil || loading {
      return
    }
    loading = true
    defer { loading = false }
    do {
      let fetched = try await WikiService.getEpisodeWikiInfo(episodeId)
      info = fetched
      name = fetched.name
      nameCN = fetched.nameCN
      epText = String(fetched.ep)
      discText = fetched.disc.map { String($0) } ?? ""
      date = fetched.date ?? ""
      type = fetched.type
      duration = fetched.duration
      summary = fetched.summary
    } catch {
      Notifier.shared.alert(error: error)
    }
  }

  private func payload(includeId: Bool) -> EpisodeWikiEditDTO? {
    guard let ep = wikiDouble(from: epText), !hasInvalidOptionalWikiDouble(discText) else {
      return nil
    }
    return EpisodeWikiEditDTO(
      id: includeId ? episodeId : nil,
      subjectID: nil,
      name: name,
      nameCN: nameCN,
      ep: ep,
      disc: episodeDisc(from: discText, preservingEmpty: true),
      date: optionalWikiText(date),
      type: type,
      duration: duration,
      summary: summary
    )
  }

  private func editPayload(info: EpisodeWikiInfoDTO) -> EpisodeWikiEditDTO? {
    guard var payload = payload(includeId: true) else {
      return nil
    }
    omitUnchangedEpisodePatchFields(
      &payload,
      original: info,
      discText: discText,
      dateText: date
    )
    return payload
  }

  private func submit() async {
    guard let info, let payload = editPayload(info: info), !saveDisabled else {
      return
    }
    submitting = true
    defer { submitting = false }
    do {
      try await WikiService.patchEpisodes(
        subjectId: info.subjectID,
        episodes: [payload],
        expectedRevision: [info.expectedRevision],
        commitMessage: commitMessage
      )
      try? await EpisodeRepository.loadEpisode(episodeId)
      Notifier.shared.notify(message: "章节 Wiki 已保存")
      onSave()
      dismiss()
    } catch {
      Notifier.shared.alert(error: error)
    }
  }

  var body: some View {
    SheetView(title: "编辑章节 Wiki", closeDisabled: submitting, applyFormStyle: true) {
      Form {
        if loading {
          ProgressView()
        }

        EpisodeWikiFields(
          name: $name,
          nameCN: $nameCN,
          epText: $epText,
          discText: $discText,
          date: $date,
          type: $type,
          duration: $duration,
          summary: $summary
        )

        Section("提交") {
          TextField("编辑摘要", text: $commitMessage)
            .textInputAutocapitalization(.never)
        }
      }
      .task {
        await load()
      }
    } controls: {
      Button {
        Task {
          await submit()
        }
      } label: {
        Label("保存", systemImage: "checkmark")
      }
      .disabled(saveDisabled)
    }
  }
}

struct SubjectWikiLockSheet: View {
  @Environment(\.dismiss) private var dismiss

  let subjectId: Int
  let locked: Bool
  let onSave: () -> Void

  @State private var reason = ""
  @State private var submitting = false

  private func submit() async {
    if reason.isEmpty || submitting {
      return
    }
    submitting = true
    defer { submitting = false }
    do {
      if locked {
        try await WikiService.unlockSubject(subjectId: subjectId, reason: reason)
      } else {
        try await WikiService.lockSubject(subjectId: subjectId, reason: reason)
      }
      _ = try? await SubjectRepository.loadSubject(subjectId)
      Notifier.shared.notify(message: locked ? "条目已解锁" : "条目已锁定")
      onSave()
      dismiss()
    } catch {
      Notifier.shared.alert(error: error)
    }
  }

  var body: some View {
    SheetView(
      title: locked ? "解锁条目" : "锁定条目",
      closeDisabled: submitting,
      applyFormStyle: true
    ) {
      Form {
        Section("原因") {
          PlaceholderTextEditor(placeholder: "请输入操作原因", text: $reason, minHeight: 100)
        }
      }
    } controls: {
      Button {
        Task {
          await submit()
        }
      } label: {
        Label(locked ? "解锁" : "锁定", systemImage: locked ? "lock.open" : "lock")
      }
      .disabled(submitting || reason.isEmpty)
    }
  }
}

struct SubjectEpisodeWikiSheet: View {
  @Environment(\.dismiss) private var dismiss

  let subjectId: Int
  let onSave: () -> Void

  @State private var mode: EpisodeWikiBatchMode = .create
  @State private var episodeIdText = ""
  @State private var name = ""
  @State private var nameCN = ""
  @State private var epText = "1"
  @State private var discText = ""
  @State private var date = ""
  @State private var type: EpisodeType = .main
  @State private var duration = ""
  @State private var summary = ""
  @State private var expectedRevision: EpisodeWikiExpectedDTO?
  @State private var loadedEpisode: EpisodeWikiInfoDTO?
  @State private var loadedEpisodeId: Int?
  @State private var commitMessage = ""
  @State private var loadingEpisode = false
  @State private var submitting = false

  private var parsedEpisodeId: Int? {
    Int(episodeIdText.trimmingCharacters(in: .whitespacesAndNewlines))
  }

  private var saveDisabled: Bool {
    if submitting || epText.isEmpty || wikiDouble(from: epText) == nil
      || hasInvalidOptionalWikiDouble(discText)
    {
      return true
    }
    switch mode {
    case .create:
      return false
    case .edit:
      return parsedEpisodeId == nil || loadedEpisodeId != parsedEpisodeId || commitMessage.isEmpty
    }
  }

  private func loadEpisode() async {
    guard let episodeId = parsedEpisodeId, !loadingEpisode else {
      return
    }
    loadingEpisode = true
    defer { loadingEpisode = false }
    do {
      let fetched = try await WikiService.getEpisodeWikiInfo(episodeId)
      guard fetched.subjectID == subjectId else {
        resetLoadedEpisode()
        Notifier.shared.alert(message: "章节不属于当前条目")
        return
      }
      name = fetched.name
      nameCN = fetched.nameCN
      epText = String(fetched.ep)
      discText = fetched.disc.map { String($0) } ?? ""
      date = fetched.date ?? ""
      type = fetched.type
      duration = fetched.duration
      summary = fetched.summary
      expectedRevision = fetched.expectedRevision
      loadedEpisode = fetched
      loadedEpisodeId = episodeId
    } catch {
      Notifier.shared.alert(error: error)
    }
  }

  private func resetLoadedEpisode() {
    expectedRevision = nil
    loadedEpisode = nil
    loadedEpisodeId = nil
  }

  private func resetEpisodeCreateFields() {
    episodeIdText = ""
    name = ""
    nameCN = ""
    epText = "1"
    discText = ""
    date = ""
    type = .main
    duration = ""
    summary = ""
    resetLoadedEpisode()
  }

  private func episodeText(_ text: String, preservingEmpty: Bool) -> String? {
    let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
    return preservingEmpty ? trimmed : optionalWikiText(text)
  }

  private func payload(id: Int?, preservingEmptyText: Bool) -> EpisodeWikiEditDTO? {
    guard let ep = wikiDouble(from: epText), !hasInvalidOptionalWikiDouble(discText) else {
      return nil
    }
    return EpisodeWikiEditDTO(
      id: id,
      subjectID: nil,
      name: episodeText(name, preservingEmpty: preservingEmptyText),
      nameCN: episodeText(nameCN, preservingEmpty: preservingEmptyText),
      ep: ep,
      disc: episodeDisc(from: discText, preservingEmpty: preservingEmptyText),
      date: optionalWikiText(date),
      type: type,
      duration: episodeText(duration, preservingEmpty: preservingEmptyText),
      summary: episodeText(summary, preservingEmpty: preservingEmptyText)
    )
  }

  private func editPayload(id: Int, original: EpisodeWikiInfoDTO) -> EpisodeWikiEditDTO? {
    guard var payload = payload(id: id, preservingEmptyText: true) else {
      return nil
    }
    omitUnchangedEpisodePatchFields(
      &payload,
      original: original,
      discText: discText,
      dateText: date
    )
    return payload
  }

  private func submit() async {
    if saveDisabled {
      return
    }
    submitting = true
    defer { submitting = false }
    do {
      switch mode {
      case .create:
        guard let payload = payload(id: nil, preservingEmptyText: false) else { return }
        let ids = try await WikiService.createEpisodes(subjectId: subjectId, episodes: [payload])
        let idsText = ids.map(String.init).joined(separator: ", ")
        Notifier.shared.notify(message: "已创建章节 #\(idsText)")
      case .edit:
        guard let episodeId = parsedEpisodeId,
          let loadedEpisode,
          let payload = editPayload(id: episodeId, original: loadedEpisode)
        else { return }
        guard loadedEpisodeId == episodeId else { return }
        try await WikiService.patchEpisodes(
          subjectId: subjectId,
          episodes: [payload],
          expectedRevision: expectedRevision.map { [$0] },
          commitMessage: commitMessage
        )
        Notifier.shared.notify(message: "章节 Wiki 已保存")
      }
      try? await EpisodeRepository.loadEpisodes(subjectId)
      onSave()
      dismiss()
    } catch {
      Notifier.shared.alert(error: error)
    }
  }

  var body: some View {
    SheetView(title: "章节 Wiki", closeDisabled: submitting, applyFormStyle: true) {
      Form {
        Section("操作") {
          Picker("模式", selection: $mode) {
            ForEach(EpisodeWikiBatchMode.allCases) { item in
              Text(item.title).tag(item)
            }
          }
          .onChange(of: mode) { _, newMode in
            switch newMode {
            case .create:
              resetEpisodeCreateFields()
            case .edit:
              resetLoadedEpisode()
            }
          }

          if mode == .edit {
            HStack {
              TextField("章节 ID", text: $episodeIdText)
                .keyboardType(.numberPad)
              Button {
                Task {
                  await loadEpisode()
                }
              } label: {
                Image(systemName: "arrow.down.doc")
              }
              .disabled(parsedEpisodeId == nil || loadingEpisode)
            }
            .onChange(of: episodeIdText) {
              resetLoadedEpisode()
            }
          }
        }

        if loadingEpisode {
          ProgressView()
        }

        EpisodeWikiFields(
          name: $name,
          nameCN: $nameCN,
          epText: $epText,
          discText: $discText,
          date: $date,
          type: $type,
          duration: $duration,
          summary: $summary
        )

        if mode == .edit {
          Section("提交") {
            TextField("编辑摘要", text: $commitMessage)
              .textInputAutocapitalization(.never)
          }
        }
      }
    } controls: {
      Button {
        Task {
          await submit()
        }
      } label: {
        Label(mode == .create ? "创建" : "保存", systemImage: "checkmark")
      }
      .disabled(saveDisabled)
    }
  }
}

private struct EpisodeWikiFields: View {
  @Binding var name: String
  @Binding var nameCN: String
  @Binding var epText: String
  @Binding var discText: String
  @Binding var date: String
  @Binding var type: EpisodeType
  @Binding var duration: String
  @Binding var summary: String

  var body: some View {
    Section("基本信息") {
      TextField("标题", text: $name)
        .textInputAutocapitalization(.never)
      TextField("中文标题", text: $nameCN)
        .textInputAutocapitalization(.never)
      TextField("章节序号", text: $epText)
        .keyboardType(.decimalPad)
      TextField("碟片序号", text: $discText)
        .keyboardType(.decimalPad)
      Picker("类型", selection: $type) {
        ForEach(EpisodeType.allCases) { item in
          Text(item.description).tag(item)
        }
      }
    }

    Section("内容") {
      TextField("日期 YYYY-MM-DD", text: $date)
        .textInputAutocapitalization(.never)
      TextField("时长", text: $duration)
        .textInputAutocapitalization(.never)
      PlaceholderTextEditor(placeholder: "简介", text: $summary, minHeight: 100)
    }
  }
}
