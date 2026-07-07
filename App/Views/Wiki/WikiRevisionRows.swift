import SwiftUI

private enum WikiContributionRevisionType {
  static let subjectMerge = 11
  static let subjectErase = 12
  static let subjectLock = 103
  static let subjectUnlock = 104
  static let characterMerge = 13
  static let characterErase = 14
  static let personMerge = 15
  static let personErase = 16
}

struct WikiSubjectRelationRevisionRow: View {
  let item: SubjectRelationRevisionDTO

  var body: some View {
    NavigationLink(value: NavDestination.subject(item.subject.id)) {
      WikiLinkedRevisionRow(
        title: item.subject.name,
        subtitle: item.subject.nameCN,
        metadata: "type \(item.type) / order \(item.order)",
        systemImage: item.subject.typeID.icon
      )
    }
    .buttonStyle(.plain)
  }
}

struct WikiSubjectCharacterRevisionRow: View {
  let item: SubjectCharacterRevisionDTO

  var body: some View {
    NavigationLink(value: NavDestination.character(item.character.id)) {
      WikiLinkedRevisionRow(
        title: item.character.name,
        subtitle: item.character.nameCN,
        metadata: "type \(item.type) / order \(item.order)",
        systemImage: WikiEntityKind.character.icon
      )
    }
    .buttonStyle(.plain)
  }
}

struct WikiSubjectPersonRevisionRow: View {
  let item: SubjectPersonRevisionDTO

  var body: some View {
    NavigationLink(value: NavDestination.person(item.person.id)) {
      WikiLinkedRevisionRow(
        title: item.person.name,
        subtitle: item.person.nameCN,
        metadata: "position \(item.position)",
        systemImage: WikiEntityKind.person.icon
      )
    }
    .buttonStyle(.plain)
  }
}

struct WikiPersonSubjectRevisionRow: View {
  let item: PersonSubjectRevisionDTO

  var body: some View {
    NavigationLink(value: NavDestination.subject(item.subject.id)) {
      WikiLinkedRevisionRow(
        title: item.subject.name,
        subtitle: item.subject.nameCN,
        metadata: "position \(item.position)",
        systemImage: item.subject.typeID.icon
      )
    }
    .buttonStyle(.plain)
  }
}

struct WikiPersonCastRevisionRow: View {
  let item: PersonCastRevisionDTO

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      NavigationLink(value: NavDestination.subject(item.subject.id)) {
        WikiLinkedRevisionRow(
          title: item.subject.name,
          subtitle: item.subject.nameCN,
          metadata: "subject #\(item.subject.id)",
          systemImage: item.subject.typeID.icon
        )
      }
      .buttonStyle(.plain)
      NavigationLink(value: NavDestination.character(item.character.id)) {
        WikiLinkedRevisionRow(
          title: item.character.name,
          subtitle: item.character.nameCN,
          metadata: "character #\(item.character.id)",
          systemImage: WikiEntityKind.character.icon
        )
      }
      .buttonStyle(.plain)
      Divider()
    }
  }
}

struct WikiCharacterSubjectRevisionRow: View {
  let item: CharacterSubjectRevisionDTO

  var body: some View {
    NavigationLink(value: NavDestination.subject(item.subject.id)) {
      WikiLinkedRevisionRow(
        title: item.subject.name,
        subtitle: item.subject.nameCN,
        metadata: "type \(item.type) / order \(item.order)",
        systemImage: item.subject.typeID.icon
      )
    }
    .buttonStyle(.plain)
  }
}

struct WikiCharacterCastRevisionRow: View {
  let item: CharacterCastRevisionDTO

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      NavigationLink(value: NavDestination.subject(item.subject.id)) {
        WikiLinkedRevisionRow(
          title: item.subject.name,
          subtitle: item.subject.nameCN,
          metadata: "subject #\(item.subject.id)",
          systemImage: item.subject.typeID.icon
        )
      }
      .buttonStyle(.plain)
      NavigationLink(value: NavDestination.person(item.person.id)) {
        WikiLinkedRevisionRow(
          title: item.person.name,
          subtitle: item.person.nameCN,
          metadata: "person #\(item.person.id)",
          systemImage: WikiEntityKind.person.icon
        )
      }
      .buttonStyle(.plain)
      Divider()
    }
  }
}

struct WikiLinkedRevisionRow: View {
  let title: String
  let subtitle: String
  let metadata: String
  let systemImage: String

  var body: some View {
    HStack(alignment: .top) {
      Image(systemName: systemImage)
        .foregroundStyle(.secondary)
        .frame(width: 24)
      VStack(alignment: .leading, spacing: 4) {
        Text(title.isEmpty ? "Untitled" : title)
          .font(.headline)
        if !subtitle.isEmpty {
          Text(subtitle)
            .font(.subheadline)
            .foregroundStyle(.secondary)
        }
        Text(metadata)
          .font(.footnote)
          .foregroundStyle(.secondary)
      }
    }
  }
}

struct WikiUserContributionsView: View {
  let user: SlimUserDTO

  var body: some View {
    List {
      Section {
        NavigationLink(value: NavDestination.wikiContributionList(user, .subject)) {
          Label("条目编辑", systemImage: WikiEntityKind.subject.icon)
        }
        NavigationLink(value: NavDestination.wikiContributionList(user, .person)) {
          Label("人物编辑", systemImage: WikiEntityKind.person.icon)
        }
        NavigationLink(value: NavDestination.wikiContributionList(user, .character)) {
          Label("角色编辑", systemImage: WikiEntityKind.character.icon)
        }
      }
      .buttonStyle(.plain)
    }
    .navigationTitle("\(user.nickname) 的 Wiki")
    .navigationBarTitleDisplayMode(.inline)
  }
}

struct WikiContributionListView: View {
  let user: SlimUserDTO
  let kind: WikiEntityKind

  private func load(limit: Int, offset: Int) async -> PagedDTO<WikiContributionRowDTO>? {
    do {
      switch kind {
      case .subject:
        let response = try await WikiService.getUserContributedSubjects(
          username: user.username,
          limit: limit,
          offset: offset
        )
        return PagedDTO(
          data: response.data.map(WikiContributionRowDTO.init),
          total: response.total
        )
      case .person:
        let response = try await WikiService.getUserContributedPersons(
          username: user.username,
          limit: limit,
          offset: offset
        )
        return PagedDTO(
          data: response.data.map(WikiContributionRowDTO.init),
          total: response.total
        )
      case .character:
        let response = try await WikiService.getUserContributedCharacters(
          username: user.username,
          limit: limit,
          offset: offset
        )
        return PagedDTO(
          data: response.data.map(WikiContributionRowDTO.init),
          total: response.total
        )
      case .episode:
        return PagedDTO(data: [], total: 0)
      }
    } catch {
      Notifier.shared.alert(error: error)
      return nil
    }
  }

  var body: some View {
    ScrollView {
      OffsetPagedView<WikiContributionRowDTO, _>(nextPageFunc: load) { item in
        WikiContributionRowView(item: item)
          .padding(.vertical, 6)
        Divider()
      }
      .padding(.horizontal, 8)
    }
    .navigationTitle("\(kind.title)编辑")
    .navigationBarTitleDisplayMode(.inline)
  }
}

struct WikiContributionRowDTO: Codable, Identifiable, Hashable, Sendable {
  let id: Int
  let kind: WikiEntityKind
  let entityId: Int
  let type: Int
  let name: String
  let commitMessage: String
  let createdAt: Int

  init(_ item: WikiSubjectContributionDTO) {
    id = item.id
    kind = .subject
    entityId = item.subjectID
    type = item.type
    name = item.name
    commitMessage = item.commitMessage
    createdAt = item.createdAt
  }

  init(_ item: WikiPersonContributionDTO) {
    id = item.id
    kind = .person
    entityId = item.personID
    type = item.type
    name = item.name
    commitMessage = item.commitMessage
    createdAt = item.createdAt
  }

  init(_ item: WikiCharacterContributionDTO) {
    id = item.id
    kind = .character
    entityId = item.characterID
    type = item.type
    name = item.name
    commitMessage = item.commitMessage
    createdAt = item.createdAt
  }

  var revisionKind: WikiHistoryKind? {
    switch kind {
    case .subject:
      switch type {
      case WikiContributionRevisionType.subjectMerge, WikiContributionRevisionType.subjectErase,
        WikiContributionRevisionType.subjectLock, WikiContributionRevisionType.subjectUnlock:
        return .subject
      default:
        return nil
      }
    case .person:
      switch type {
      case WikiContributionRevisionType.personMerge, WikiContributionRevisionType.personErase:
        return .person
      default:
        return nil
      }
    case .character:
      switch type {
      case WikiContributionRevisionType.characterMerge, WikiContributionRevisionType.characterErase:
        return .character
      default:
        return nil
      }
    case .episode:
      return nil
    }
  }
}

struct WikiContributionRowView: View {
  let item: WikiContributionRowDTO

  var body: some View {
    NavigationLink(value: destination) {
      VStack(alignment: .leading, spacing: 6) {
        HStack {
          Label(item.name, systemImage: item.kind.icon)
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
      }
    }
    .buttonStyle(.plain)
  }

  private var destination: NavDestination {
    if let revisionKind = item.revisionKind {
      return .wikiRevision(revisionKind, item.id)
    }

    switch item.kind {
    case .subject:
      return .subject(item.entityId)
    case .person:
      return .person(item.entityId)
    case .character:
      return .character(item.entityId)
    case .episode:
      return .episode(item.entityId)
    }
  }
}
