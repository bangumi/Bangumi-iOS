import SwiftUI

struct WikiHomeView: View {
  @AppStorage("profile") private var profile: Profile = Profile()
  @AppStorage("isAuthenticated") private var isAuthenticated = false

  private var canAccessWikiTools: Bool {
    isAuthenticated && profile.canAccessWikiTools
  }

  private var canCreateWikiEntities: Bool {
    profile.canEditSubjectWiki || profile.groupEnum.canEditMonoWiki
  }

  var body: some View {
    List {
      if canAccessWikiTools {
        Section("最近更新") {
          NavigationLink(value: NavDestination.wikiRecent(.subject)) {
            Label("最近条目 Wiki", systemImage: WikiEntityKind.subject.icon)
          }
          NavigationLink(value: NavDestination.wikiRecent(.person)) {
            Label("最近人物 Wiki", systemImage: WikiEntityKind.person.icon)
          }
          NavigationLink(value: NavDestination.wikiRecent(.character)) {
            Label("最近角色 Wiki", systemImage: WikiEntityKind.character.icon)
          }
          NavigationLink(value: NavDestination.wikiRecent(.episode)) {
            Label("最近章节 Wiki", systemImage: WikiEntityKind.episode.icon)
          }
        }
        .buttonStyle(.plain)

        if canCreateWikiEntities {
          Section("创建") {
            if profile.canEditSubjectWiki {
              NavigationLink(value: NavDestination.wikiCreate(.subject)) {
                Label("创建条目", systemImage: "plus.rectangle.on.rectangle")
              }
            }
            if profile.groupEnum.canEditMonoWiki {
              NavigationLink(value: NavDestination.wikiCreate(.person)) {
                Label("创建人物", systemImage: "person.badge.plus")
              }
              NavigationLink(value: NavDestination.wikiCreate(.character)) {
                Label("创建角色", systemImage: "theatermasks.circle")
              }
            }
          }
          .buttonStyle(.plain)
        }

        if !profile.username.isEmpty {
          Section("我的贡献") {
            NavigationLink(value: NavDestination.wikiUserContributions(profile.user)) {
              Label("Wiki 编辑记录", systemImage: "clock.arrow.circlepath")
            }
          }
          .buttonStyle(.plain)
        }
      } else {
        Section {
          Text("当前账号没有 Wiki 权限")
            .foregroundStyle(.secondary)
        }
      }
    }
    .navigationTitle("Wiki")
    .navigationBarTitleDisplayMode(.inline)
  }
}

struct WikiRecentView: View {
  let kind: WikiEntityKind

  @State private var subjectItems: [WikiRecentItemDTO] = []
  @State private var personItems: [WikiRecentItemDTO] = []
  @State private var items: [WikiRecentItemDTO] = []
  @State private var loaded = false
  @State private var loading = false

  private func load(force: Bool = false) async {
    if loading || loaded && !force {
      return
    }
    loading = true
    defer { loading = false }
    do {
      switch kind {
      case .subject:
        let response = try await WikiService.getRecentSubjects()
        subjectItems = response.subject
        personItems = response.persons
      case .person:
        items = try await WikiService.getRecentPersons()
      case .character:
        items = try await WikiService.getRecentCharacters()
      case .episode:
        items = try await WikiService.getRecentEpisodes()
      }
      loaded = true
    } catch {
      Notifier.shared.alert(error: error)
    }
  }

  var body: some View {
    List {
      if kind == .subject {
        Section("条目") {
          ForEach(Array(subjectItems.enumerated()), id: \.offset) { _, item in
            WikiRecentRowView(kind: .subject, item: item)
          }
        }
        Section("人物") {
          ForEach(Array(personItems.enumerated()), id: \.offset) { _, item in
            WikiRecentRowView(kind: .person, item: item)
          }
        }
      } else {
        ForEach(Array(items.enumerated()), id: \.offset) { _, item in
          WikiRecentRowView(kind: kind, item: item)
        }
      }
    }
    .overlay {
      if loading && !loaded {
        ProgressView()
      }
    }
    .task {
      await load()
    }
    .refreshable {
      await load(force: true)
    }
    .navigationTitle("最近\(kind.title) Wiki")
    .navigationBarTitleDisplayMode(.inline)
  }
}

struct WikiRecentRowView: View {
  let kind: WikiEntityKind
  let item: WikiRecentItemDTO

  var body: some View {
    NavigationLink(value: destination) {
      VStack(alignment: .leading, spacing: 4) {
        Label("\(kind.title) #\(item.id)", systemImage: kind.icon)
        Text(item.createdAt.datetimeDisplay)
          .font(.footnote)
          .foregroundStyle(.secondary)
      }
    }
    .buttonStyle(.plain)
  }

  private var destination: NavDestination {
    switch kind {
    case .subject:
      return .subject(item.id)
    case .person:
      return .person(item.id)
    case .character:
      return .character(item.id)
    case .episode:
      return .episode(item.id)
    }
  }
}

struct WikiHistoryView: View {
  let kind: WikiHistoryKind
  let entityId: Int

  @State private var reloader = false

  private func load(limit: Int, offset: Int) async -> PagedDTO<WikiRevisionHistoryDTO>? {
    do {
      return try await WikiService.getHistory(
        kind: kind,
        entityId: entityId,
        limit: limit,
        offset: offset
      )
    } catch {
      Notifier.shared.alert(error: error)
      return nil
    }
  }

  var body: some View {
    ScrollView {
      OffsetPagedView<WikiRevisionHistoryDTO, _>(reloader: reloader, nextPageFunc: load) { item in
        WikiRevisionHistoryRowView(kind: kind, item: item)
          .padding(.vertical, 6)
        Divider()
      }
      .padding(.horizontal, 8)
    }
    .refreshable {
      reloader.toggle()
    }
    .navigationTitle(kind.title)
    .navigationBarTitleDisplayMode(.inline)
  }
}

struct WikiRevisionHistoryRowView: View {
  let kind: WikiHistoryKind
  let item: WikiRevisionHistoryDTO

  var body: some View {
    NavigationLink(value: NavDestination.wikiRevision(kind, item.id)) {
      VStack(alignment: .leading, spacing: 6) {
        HStack(alignment: .firstTextBaseline) {
          Label("#\(item.id)", systemImage: kind.icon)
            .font(.headline)
          Spacer()
          Text(item.createdAt.datetimeDisplay)
            .font(.footnote)
            .foregroundStyle(.secondary)
        }
        if !item.commitMessage.isEmpty {
          Text(item.commitMessage)
            .font(.subheadline)
            .foregroundStyle(.secondary)
            .lineLimit(2)
        }
        Text("by \(item.creator.nickname)")
          .font(.footnote)
          .foregroundStyle(.secondary)
      }
    }
    .buttonStyle(.plain)
  }
}

struct WikiRevisionDetailView: View {
  let kind: WikiHistoryKind
  let revisionId: Int

  @State private var payload: WikiRevisionPayload?
  @State private var loading = false

  private func load() async {
    loading = true
    defer { loading = false }
    do {
      switch kind {
      case .subject:
        payload = .subject(try await WikiService.getSubjectRevision(revisionId))
      case .subjectRelations:
        payload = .subjectRelations(try await WikiService.getSubjectRelationRevision(revisionId))
      case .subjectCharacters:
        payload = .subjectCharacters(try await WikiService.getSubjectCharacterRevision(revisionId))
      case .subjectPersons:
        payload = .subjectPersons(try await WikiService.getSubjectPersonRevision(revisionId))
      case .person:
        payload = .person(try await WikiService.getPersonRevision(revisionId))
      case .personSubjects:
        payload = .personSubjects(try await WikiService.getPersonSubjectRevision(revisionId))
      case .personCasts:
        payload = .personCasts(try await WikiService.getPersonCastRevision(revisionId))
      case .character:
        payload = .character(try await WikiService.getCharacterRevision(revisionId))
      case .characterSubjects:
        payload = .characterSubjects(try await WikiService.getCharacterSubjectRevision(revisionId))
      case .characterCasts:
        payload = .characterCasts(try await WikiService.getCharacterCastRevision(revisionId))
      }
    } catch {
      Notifier.shared.alert(error: error)
    }
  }

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 16) {
        if loading {
          ProgressView()
        }
        if let payload {
          WikiRevisionPayloadView(payload: payload)
        }
      }
      .padding(8)
    }
    .task {
      await load()
    }
    .refreshable {
      await load()
    }
    .navigationTitle(kind.revisionTitle)
    .navigationBarTitleDisplayMode(.inline)
  }
}

enum WikiRevisionPayload: Hashable {
  case subject(SubjectWikiRevisionDTO)
  case person(PersonWikiRevisionDTO)
  case character(CharacterWikiRevisionDTO)
  case subjectRelations([SubjectRelationRevisionDTO])
  case subjectCharacters([SubjectCharacterRevisionDTO])
  case subjectPersons([SubjectPersonRevisionDTO])
  case personSubjects([PersonSubjectRevisionDTO])
  case personCasts([PersonCastRevisionDTO])
  case characterSubjects([CharacterSubjectRevisionDTO])
  case characterCasts([CharacterCastRevisionDTO])
}

struct WikiRevisionPayloadView: View {
  let payload: WikiRevisionPayload

  var body: some View {
    VStack(alignment: .leading, spacing: 16) {
      switch payload {
      case .subject(let revision):
        WikiTextSection(title: "名称", text: revision.name)
        WikiTextSection(title: "摘要", text: revision.summary)
        WikiTextSection(title: "标签", text: revision.metaTags.formatted())
        WikiTextSection(title: "Infobox", text: revision.infobox, monospaced: true)
      case .person(let revision):
        WikiTextSection(title: "名称", text: revision.name)
        WikiTextSection(title: "摘要", text: revision.summary)
        WikiTextSection(title: "职业", text: revision.profession.enabledLabels.formatted())
        WikiTextSection(title: "Infobox", text: revision.infobox, monospaced: true)
      case .character(let revision):
        WikiTextSection(title: "名称", text: revision.name)
        WikiTextSection(title: "摘要", text: revision.summary)
        WikiTextSection(title: "Infobox", text: revision.infobox, monospaced: true)
      case .subjectRelations(let items):
        ForEach(items) { item in
          WikiSubjectRelationRevisionRow(item: item)
        }
      case .subjectCharacters(let items):
        ForEach(items) { item in
          WikiSubjectCharacterRevisionRow(item: item)
        }
      case .subjectPersons(let items):
        ForEach(items) { item in
          WikiSubjectPersonRevisionRow(item: item)
        }
      case .personSubjects(let items):
        ForEach(items) { item in
          WikiPersonSubjectRevisionRow(item: item)
        }
      case .personCasts(let items):
        ForEach(items) { item in
          WikiPersonCastRevisionRow(item: item)
        }
      case .characterSubjects(let items):
        ForEach(items) { item in
          WikiCharacterSubjectRevisionRow(item: item)
        }
      case .characterCasts(let items):
        ForEach(items) { item in
          WikiCharacterCastRevisionRow(item: item)
        }
      }
    }
    .frame(maxWidth: .infinity, alignment: .leading)
  }
}

struct WikiTextSection: View {
  let title: String
  let text: String
  var monospaced = false

  var body: some View {
    VStack(alignment: .leading, spacing: 6) {
      Text(title)
        .font(.headline)
      Text(text.isEmpty ? " " : text)
        .font(monospaced ? .system(.body, design: .monospaced) : .body)
        .textSelection(.enabled)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
  }
}

struct PlaceholderTextEditor: View {
  let placeholder: String
  @Binding var text: String
  let minHeight: CGFloat
  var monospaced = false

  var body: some View {
    TextEditor(text: $text)
      .font(monospaced ? .system(.body, design: .monospaced) : .body)
      .frame(minHeight: minHeight)
      .overlay(alignment: .topLeading) {
        if text.isEmpty {
          Text(placeholder)
            .foregroundColor(.secondary.opacity(0.5))
            .padding(.top, 8)
            .padding(.leading, 4)
        }
      }
  }
}

extension PersonProfessionDTO {
  var enabledLabels: [String] {
    PersonCareer.allCases.filter { career in
      career != .none && self[career]
    }.map(\.description)
  }
}
