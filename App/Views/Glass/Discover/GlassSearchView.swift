import OSLog
import SwiftUI

extension SearchType {
  var glassTitle: String {
    switch self {
    case .subject:
      "条目"
    case .character:
      "角色"
    case .person:
      "人物"
    }
  }
}

struct GlassSearchView: View {
  let text: String
  @Binding var remote: Bool

  @Environment(\.theme) private var theme

  @State private var searchType: SearchType = .subject
  @State private var subjectType: SubjectType = .none
  @State private var localCount: Int = 0
  @State private var remoteTotal: Int = 0

  private var indicatorTint: (fill: Color, text: Color) {
    theme.subjectTint(remote ? .book : .game)
  }

  private var indicatorTitle: String {
    if remote {
      return remoteTotal > 0 ? "全站 · 共 \(remoteTotal) 条" : "全站 · 搜索中…"
    }
    return "本地 · 即时结果 \(localCount) 条"
  }

  private var indicatorRow: some View {
    HStack(spacing: 8) {
      Label(indicatorTitle, systemImage: remote ? "globe" : "internaldrive")
        .font(.caption.weight(.bold))
        .foregroundStyle(indicatorTint.text)
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
        .background(indicatorTint.fill, in: Capsule())
      Spacer(minLength: 0)
      Text(remote ? "修改关键字退回本地搜索" : "回车搜索全站 ↵")
        .font(.caption)
        .foregroundStyle(theme.tertiaryText)
    }
    .padding(.horizontal, 3)
  }

  private var typeChips: some View {
    ScrollView(.horizontal, showsIndicators: false) {
      HStack(spacing: 6) {
        chip(for: .none)
        ForEach(SubjectType.allTypes) { type in
          chip(for: type)
        }
      }
      .padding(.horizontal, 2)
    }
    .scrollClipDisabled()
  }

  private func chip(for type: SubjectType) -> some View {
    GlassChip(title: type.description, isSelected: subjectType == type) {
      withAnimation(.default) {
        subjectType = type
      }
    }
  }

  @ViewBuilder
  private var results: some View {
    switch searchType {
    case .subject:
      if remote {
        GlassSubjectRemoteResults(text: text, subjectType: subjectType, total: $remoteTotal)
      } else {
        GlassSubjectLocalResults(text: text, subjectType: subjectType, count: $localCount)
      }
    case .character:
      if remote {
        GlassCharacterRemoteResults(text: text, total: $remoteTotal)
      } else {
        GlassCharacterLocalResults(text: text, count: $localCount)
      }
    case .person:
      if remote {
        GlassPersonRemoteResults(text: text, total: $remoteTotal)
      } else {
        GlassPersonLocalResults(text: text, count: $localCount)
      }
    }
  }

  var body: some View {
    VStack(alignment: .leading, spacing: theme.metrics.listSpacing) {
      GlassSegmented(
        selection: $searchType.animated(),
        items: [SearchType.subject, .character, .person]
      ) { item in
        Text(item.glassTitle)
      }
      if searchType == .subject, !text.isEmpty {
        typeChips
      }
      if text.isEmpty {
        GlassEmptyCard(
          systemImage: "magnifyingglass",
          title: "输入关键字搜索",
          description: "边输入即时匹配本地收藏与缓存\n回车搜索全站"
        )
        .padding(.top, 24)
      } else {
        indicatorRow
        results
        if !remote {
          Text("以上来自本地缓存（我收藏/浏览过的条目）· 按回车搜索全站")
            .font(.caption)
            .foregroundStyle(theme.tertiaryText)
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
            .padding(.top, 2)
        }
      }
    }
    .onChange(of: searchType) { _, _ in
      remoteTotal = 0
      localCount = 0
    }
    .onChange(of: text) { _, _ in
      remoteTotal = 0
    }
  }
}

private func glassHighlighted(
  _ value: String, keyword: String, tint: Color
) -> AttributedString {
  var text = AttributedString(value)
  let keyword = keyword.trimmingCharacters(in: .whitespacesAndNewlines)
  guard !keyword.isEmpty,
    let range = text.range(of: keyword, options: [.caseInsensitive])
  else {
    return text
  }
  text[range].backgroundColor = tint
  return text
}

private struct GlassSearchSubjectRow: View {
  let subject: SlimSubjectDTO
  let initialCollectionType: CollectionType
  let keyword: String
  let reload: (() async -> Void)?

  @AppStorage("titlePreference") var titlePreference: TitlePreference = .original

  @Environment(\.theme) private var theme

  @State private var collectionType: CollectionType

  init(
    subject: SlimSubjectDTO, collectionType: CollectionType, keyword: String,
    reload: (() async -> Void)?
  ) {
    self.subject = subject
    self.initialCollectionType = collectionType
    self.keyword = keyword
    self.reload = reload
    self._collectionType = State(initialValue: collectionType)
  }

  private func loadCollectionType() async {
    do {
      let db = try await AppContext.shared.getDB()
      collectionType =
        try await db.getCollectionTypes(subjectIds: [subject.id])[subject.id] ?? .none
    } catch {
      Logger.app.error("Failed to load subject collection type: \(error)")
    }
  }

  private func handleSubjectInvalidation(_ notification: Notification) {
    guard ProgressSubjectInvalidation.subjectId(from: notification) == subject.id else {
      return
    }
    Task {
      await loadCollectionType()
    }
  }

  private var metaText: String {
    var parts: [String] = []
    if let info = subject.info, !info.isEmpty {
      parts.append(info)
    }
    parts.append(contentsOf: subject.metaTags)
    return parts.joined(separator: " · ")
  }

  @ViewBuilder
  private var ratingLine: some View {
    if let rating = subject.rating {
      HStack(spacing: 5) {
        if rating.total > 10, rating.score > 0 {
          Text(rating.score.rateDisplay)
            .font(.caption.weight(.heavy).monospaced())
            .foregroundStyle(theme.accentDeep)
          StarsView(score: rating.score, size: 9)
          Text("(\(rating.total)人评分)")
            .font(.caption2)
            .foregroundStyle(theme.tertiaryText)
        } else {
          StarsView(score: 0, size: 9)
          Text("(少于10人评分)")
            .font(.caption2)
            .foregroundStyle(theme.tertiaryText)
        }
        if rating.rank > 0 {
          Text("#\(rating.rank)")
            .font(.caption2.weight(.semibold).monospaced())
            .foregroundStyle(theme.rank)
        }
        Spacer(minLength: 0)
      }
    }
  }

  var body: some View {
    NavigationLink(value: NavDestination.subject(subject.id)) {
      CardView(padding: 12) {
        HStack(alignment: .top, spacing: 12) {
          ImageView(img: subject.images?.resize(.r200))
            .imageStyle(width: 46, height: 64)
            .imageType(.subject)
            .imageNSFW(subject.nsfw)
          VStack(alignment: .leading, spacing: 4) {
            Text(
              glassHighlighted(
                subject.title(with: titlePreference), keyword: keyword,
                tint: theme.accent.opacity(0.25))
            )
            .font(.subheadline.weight(.bold))
            .foregroundStyle(theme.cardTitle)
            .multilineTextAlignment(.leading)
            .lineLimit(2)
            HStack(spacing: 5) {
              GlassTypeBadge(type: subject.type)
              if !metaText.isEmpty {
                Text(metaText)
                  .font(.caption)
                  .foregroundStyle(theme.secondaryText)
                  .lineLimit(1)
              }
            }
            ratingLine
          }
          Spacer(minLength: 0)
          GlassCollectionBadge(type: collectionType, subjectType: subject.type)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
      }
    }
    .buttonStyle(.plain)
    .subjectPreview(subject, collectionType: collectionType) {
      await reload?()
      await loadCollectionType()
    }
    .onChange(of: initialCollectionType) { _, newValue in
      collectionType = newValue
    }
    .onReceive(
      NotificationCenter.default.publisher(for: ProgressSubjectInvalidation.notificationName),
      perform: handleSubjectInvalidation
    )
  }
}

private struct GlassSearchMonoRow: View {
  let destination: NavDestination
  let title: String
  let info: String
  let comment: Int
  let imageURL: String?
  let nsfw: Bool
  let collected: Bool
  let keyword: String

  @Environment(\.theme) private var theme

  var body: some View {
    NavigationLink(value: destination) {
      CardView(padding: 12) {
        HStack(spacing: 12) {
          ImageView(img: imageURL)
            .imageStyle(width: 44, height: 44, cornerRadius: 22)
            .imageType(.avatar)
            .imageNSFW(nsfw)
            .imageCollectedStatus(collected)
          VStack(alignment: .leading, spacing: 3) {
            Text(
              glassHighlighted(title, keyword: keyword, tint: theme.accent.opacity(0.25))
            )
              .font(.subheadline.weight(.bold))
              .foregroundStyle(theme.cardTitle)
              .multilineTextAlignment(.leading)
              .lineLimit(1)
            if !info.isEmpty {
              Text(info)
                .font(.caption)
                .foregroundStyle(theme.secondaryText)
                .multilineTextAlignment(.leading)
                .lineLimit(2)
            }
            if comment > 0 {
              Text("评论 \(comment)")
                .font(.caption2.weight(.semibold).monospaced())
                .foregroundStyle(theme.tertiaryText)
            }
          }
          Spacer(minLength: 0)
          Image(systemName: "chevron.right")
            .font(.caption2.weight(.bold))
            .foregroundStyle(theme.tertiaryText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
      }
    }
    .buttonStyle(.plain)
  }
}

private struct GlassSearchEmptyResults: View {
  let remote: Bool

  var body: some View {
    GlassEmptyCard(
      systemImage: "questionmark.circle",
      title: remote ? "没有找到相关结果" : "本地缓存没有匹配结果",
      description: remote ? "换个关键字再试试" : "按回车搜索全站"
    )
  }
}

private struct GlassSubjectLocalResults: View {
  let text: String
  let subjectType: SubjectType
  @Binding var count: Int

  @Environment(\.theme) private var theme

  @State private var subjects: [SubjectDTO] = []

  private func load() async {
    do {
      let db = try await AppContext.shared.getDB()
      let fetched = try await db.fetchLocalSubjects(
        search: text.gb,
        subjectType: subjectType
      )
      withAnimation(.default) {
        subjects = fetched
      }
      count = fetched.count
    } catch {
      Notifier.shared.alert(error: error)
    }
  }

  var body: some View {
    LazyVStack(spacing: theme.metrics.listSpacing) {
      ForEach(subjects) { subject in
        GlassSearchSubjectRow(
          subject: subject.slim,
          collectionType: subject.ctypeEnum,
          keyword: text,
          reload: load
        )
      }
      if subjects.isEmpty {
        GlassSearchEmptyResults(remote: false)
      }
    }
    .task(id: "\(text)-\(subjectType.rawValue)") {
      await load()
    }
  }
}

private struct GlassSubjectRemoteResults: View {
  let text: String
  let subjectType: SubjectType
  @Binding var total: Int

  @State private var reloader = false

  private func fetch(limit: Int, offset: Int) async -> PagedDTO<SubjectListItemDTO>? {
    do {
      guard let db = await AppContext.shared.databaseIfAvailable() else {
        throw ChiiError.uninitialized
      }
      let resp = try await SearchService.searchSubjects(
        keyword: text.gb, type: subjectType, limit: limit, offset: offset)
      for item in resp.data {
        try await db.saveSubject(item)
      }
      total = resp.total
      return PagedDTO(data: try await db.makeSubjectListItems(resp.data), total: resp.total)
    } catch {
      Notifier.shared.alert(error: error)
    }
    return nil
  }

  var body: some View {
    OffsetPagedView<SubjectListItemDTO, _>(reloader: reloader, nextPageFunc: fetch) { item in
      GlassSearchSubjectRow(
        subject: item.subject,
        collectionType: item.collectionType,
        keyword: text,
        reload: nil
      )
    }
    .onChange(of: subjectType) { _, _ in
      withAnimation(.default) {
        reloader.toggle()
      }
    }
  }
}

private struct GlassCharacterRow: View {
  let character: CharacterDTO
  let keyword: String

  @AppStorage("titlePreference") var titlePreference: TitlePreference = .original

  var body: some View {
    GlassSearchMonoRow(
      destination: .character(character.id),
      title: character.title(with: titlePreference),
      info: character.info,
      comment: character.comment,
      imageURL: character.images?.resize(.r200),
      nsfw: character.nsfw,
      collected: (character.collectedAt ?? 0) > 0,
      keyword: keyword
    )
  }
}

private struct GlassPersonRow: View {
  let person: PersonDTO
  let keyword: String

  @AppStorage("titlePreference") var titlePreference: TitlePreference = .original

  var body: some View {
    GlassSearchMonoRow(
      destination: .person(person.id),
      title: person.title(with: titlePreference),
      info: person.info,
      comment: person.comment,
      imageURL: person.images?.resize(.r200),
      nsfw: person.nsfw,
      collected: (person.collectedAt ?? 0) > 0,
      keyword: keyword
    )
  }
}

private struct GlassCharacterLocalResults: View {
  let text: String
  @Binding var count: Int

  @Environment(\.theme) private var theme

  @State private var characters: [CharacterDTO] = []

  private func load() async {
    do {
      let db = try await AppContext.shared.getDB()
      let fetched = try await db.fetchLocalCharacters(search: text.gb)
      withAnimation(.default) {
        characters = fetched
      }
      count = fetched.count
    } catch {
      Notifier.shared.alert(error: error)
    }
  }

  private func handleMonoCollectionInvalidation(_ notification: Notification) {
    guard let characterId = MonoCollectionInvalidation.characterId(from: notification),
      characters.contains(where: { $0.id == characterId })
    else {
      return
    }
    Task {
      await load()
    }
  }

  var body: some View {
    LazyVStack(spacing: theme.metrics.listSpacing) {
      ForEach(characters) { character in
        GlassCharacterRow(character: character, keyword: text)
      }
      if characters.isEmpty {
        GlassSearchEmptyResults(remote: false)
      }
    }
    .task(id: text) {
      await load()
    }
    .onReceive(
      NotificationCenter.default.publisher(for: MonoCollectionInvalidation.notificationName),
      perform: handleMonoCollectionInvalidation
    )
  }
}

private struct GlassCharacterRemoteResults: View {
  let text: String
  @Binding var total: Int

  private func fetch(limit: Int, offset: Int) async -> PagedDTO<SlimCharacterDTO>? {
    do {
      guard let db = await AppContext.shared.databaseIfAvailable() else {
        throw ChiiError.uninitialized
      }
      let resp = try await SearchService.searchCharacters(
        keyword: text.gb, limit: limit, offset: offset)
      for item in resp.data {
        try await db.saveCharacter(item)
      }
      total = resp.total
      return resp
    } catch {
      Notifier.shared.alert(error: error)
    }
    return nil
  }

  var body: some View {
    OffsetPagedView<SlimCharacterDTO, _>(nextPageFunc: fetch) { item in
      GlassCharacterRemoteItem(characterId: item.id, keyword: text)
    }
  }
}

private struct GlassCharacterRemoteItem: View {
  let characterId: Int
  let keyword: String

  @State private var character: CharacterDTO?

  private func load() async {
    do {
      let db = try await AppContext.shared.getDB()
      character = try await db.getCharacterDTO(characterId)
    } catch {
      Notifier.shared.alert(error: error)
    }
  }

  private func handleMonoCollectionInvalidation(_ notification: Notification) {
    guard MonoCollectionInvalidation.characterId(from: notification) == characterId else {
      return
    }
    Task {
      await load()
    }
  }

  var body: some View {
    Group {
      if let character = character {
        GlassCharacterRow(character: character, keyword: keyword)
      }
    }
    .task(id: characterId) {
      await load()
    }
    .onReceive(
      NotificationCenter.default.publisher(for: MonoCollectionInvalidation.notificationName),
      perform: handleMonoCollectionInvalidation
    )
    .onAppear {
      Task {
        await load()
      }
    }
  }
}

private struct GlassPersonLocalResults: View {
  let text: String
  @Binding var count: Int

  @Environment(\.theme) private var theme

  @State private var persons: [PersonDTO] = []

  private func load() async {
    do {
      let db = try await AppContext.shared.getDB()
      let fetched = try await db.fetchLocalPersons(search: text.gb)
      withAnimation(.default) {
        persons = fetched
      }
      count = fetched.count
    } catch {
      Notifier.shared.alert(error: error)
    }
  }

  private func handleMonoCollectionInvalidation(_ notification: Notification) {
    guard let personId = MonoCollectionInvalidation.personId(from: notification),
      persons.contains(where: { $0.id == personId })
    else {
      return
    }
    Task {
      await load()
    }
  }

  var body: some View {
    LazyVStack(spacing: theme.metrics.listSpacing) {
      ForEach(persons) { person in
        GlassPersonRow(person: person, keyword: text)
      }
      if persons.isEmpty {
        GlassSearchEmptyResults(remote: false)
      }
    }
    .task(id: text) {
      await load()
    }
    .onReceive(
      NotificationCenter.default.publisher(for: MonoCollectionInvalidation.notificationName),
      perform: handleMonoCollectionInvalidation
    )
  }
}

private struct GlassPersonRemoteResults: View {
  let text: String
  @Binding var total: Int

  private func fetch(limit: Int, offset: Int) async -> PagedDTO<SlimPersonDTO>? {
    do {
      guard let db = await AppContext.shared.databaseIfAvailable() else {
        throw ChiiError.uninitialized
      }
      let resp = try await SearchService.searchPersons(
        keyword: text.gb, limit: limit, offset: offset)
      for item in resp.data {
        try await db.savePerson(item)
      }
      total = resp.total
      return resp
    } catch {
      Notifier.shared.alert(error: error)
    }
    return nil
  }

  var body: some View {
    OffsetPagedView<SlimPersonDTO, _>(nextPageFunc: fetch) { item in
      GlassPersonRemoteItem(personId: item.id, keyword: text)
    }
  }
}

private struct GlassPersonRemoteItem: View {
  let personId: Int
  let keyword: String

  @State private var person: PersonDTO?

  private func load() async {
    do {
      let db = try await AppContext.shared.getDB()
      person = try await db.getPersonDTO(personId)
    } catch {
      Notifier.shared.alert(error: error)
    }
  }

  private func handleMonoCollectionInvalidation(_ notification: Notification) {
    guard MonoCollectionInvalidation.personId(from: notification) == personId else {
      return
    }
    Task {
      await load()
    }
  }

  var body: some View {
    Group {
      if let person = person {
        GlassPersonRow(person: person, keyword: keyword)
      }
    }
    .task(id: personId) {
      await load()
    }
    .onReceive(
      NotificationCenter.default.publisher(for: MonoCollectionInvalidation.notificationName),
      perform: handleMonoCollectionInvalidation
    )
    .onAppear {
      Task {
        await load()
      }
    }
  }
}
