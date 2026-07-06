import Foundation

private extension String {
  var nilIfEmpty: String? {
    isEmpty ? nil : self
  }
}

enum WikiEntityKind: String, Codable, Hashable, Identifiable, CaseIterable {
  case subject
  case person
  case character
  case episode

  var id: Self {
    self
  }

  var title: String {
    switch self {
    case .subject:
      return "条目"
    case .person:
      return "人物"
    case .character:
      return "角色"
    case .episode:
      return "章节"
    }
  }

  var icon: String {
    switch self {
    case .subject:
      return "rectangle.stack"
    case .person:
      return "person"
    case .character:
      return "theatermasks"
    case .episode:
      return "list.number"
    }
  }
}

enum WikiHistoryKind: String, Codable, Hashable, Identifiable, CaseIterable {
  case subject
  case subjectRelations
  case subjectCharacters
  case subjectPersons
  case person
  case personSubjects
  case personCasts
  case character
  case characterSubjects
  case characterCasts

  var id: Self {
    self
  }

  var title: String {
    switch self {
    case .subject:
      return "条目信息"
    case .subjectRelations:
      return "关联条目"
    case .subjectCharacters:
      return "关联角色"
    case .subjectPersons:
      return "制作人员"
    case .person:
      return "人物信息"
    case .personSubjects:
      return "参与作品"
    case .personCasts:
      return "出演角色"
    case .character:
      return "角色信息"
    case .characterSubjects:
      return "出演作品"
    case .characterCasts:
      return "关联人物"
    }
  }

  var icon: String {
    switch self {
    case .subject, .person, .character:
      return "doc.text"
    case .subjectRelations, .subjectCharacters, .subjectPersons, .personSubjects, .personCasts,
      .characterSubjects, .characterCasts:
      return "link"
    }
  }

  var revisionTitle: String {
    "\(title)历史版本"
  }

  var entityKind: WikiEntityKind {
    switch self {
    case .subject, .subjectRelations, .subjectCharacters, .subjectPersons:
      return .subject
    case .person, .personSubjects, .personCasts:
      return .person
    case .character, .characterSubjects, .characterCasts:
      return .character
    }
  }
}

struct WikiPlatformDTO: Codable, Hashable, Sendable, Identifiable {
  var id: Int
  var text: String
  var wikiTpl: String?
}

struct SubjectWikiInfoDTO: Codable, Hashable, Sendable, Identifiable {
  var id: Int
  var name: String
  var typeID: SubjectType
  var infobox: String
  var locked: Bool
  var redirect: Int
  var platform: Int
  var availablePlatform: [WikiPlatformDTO]
  var metaTags: [String]
  var summary: String
  var series: Bool?
  var nsfw: Bool

  var edit: SubjectWikiEditDTO {
    SubjectWikiEditDTO(
      name: name,
      infobox: infobox,
      platform: platform,
      series: series,
      nsfw: nsfw,
      metaTags: metaTags,
      summary: summary
    )
  }

  var expectedRevision: SubjectWikiExpectedDTO {
    SubjectWikiExpectedDTO(
      name: name.nilIfEmpty,
      infobox: infobox.nilIfEmpty,
      platform: platform,
      summary: summary.nilIfEmpty,
      metaTags: metaTags
    )
  }
}

struct SubjectWikiEditDTO: Codable, Hashable, Sendable {
  var name: String
  var infobox: String
  var platform: Int
  var series: Bool?
  var nsfw: Bool
  var metaTags: [String]
  var summary: String
  var date: String?
}

struct SubjectWikiExpectedDTO: Codable, Hashable, Sendable {
  var name: String?
  var infobox: String?
  var platform: Int?
  var summary: String?
  var metaTags: [String]?
}

struct SubjectWikiRevisionDTO: Codable, Hashable, Sendable, Identifiable {
  var id: Int
  var name: String
  var infobox: String
  var metaTags: [String]
  var summary: String
}

struct PersonProfessionDTO: Codable, Hashable, Sendable {
  var producer: Bool?
  var mangaka: Bool?
  var artist: Bool?
  var seiyu: Bool?
  var writer: Bool?
  var illustrator: Bool?
  var actor: Bool?

  init(
    producer: Bool? = nil,
    mangaka: Bool? = nil,
    artist: Bool? = nil,
    seiyu: Bool? = nil,
    writer: Bool? = nil,
    illustrator: Bool? = nil,
    actor: Bool? = nil
  ) {
    self.producer = producer
    self.mangaka = mangaka
    self.artist = artist
    self.seiyu = seiyu
    self.writer = writer
    self.illustrator = illustrator
    self.actor = actor
  }

  subscript(_ career: PersonCareer) -> Bool {
    get {
      switch career {
      case .producer:
        return producer ?? false
      case .mangaka:
        return mangaka ?? false
      case .artist:
        return artist ?? false
      case .seiyu:
        return seiyu ?? false
      case .writer:
        return writer ?? false
      case .illustrator:
        return illustrator ?? false
      case .actor:
        return actor ?? false
      case .none:
        return false
      }
    }
    set {
      switch career {
      case .producer:
        producer = newValue
      case .mangaka:
        mangaka = newValue
      case .artist:
        artist = newValue
      case .seiyu:
        seiyu = newValue
      case .writer:
        writer = newValue
      case .illustrator:
        illustrator = newValue
      case .actor:
        actor = newValue
      case .none:
        break
      }
    }
  }

  var bodyValue: [String: Bool] {
    var result: [String: Bool] = [:]
    for career in PersonCareer.allCases where career != .none {
      result[career.rawValue] = self[career]
    }
    return result
  }
}

struct PersonWikiInfoDTO: Codable, Hashable, Sendable, Identifiable {
  var id: Int
  var name: String
  var typeID: PersonType
  var infobox: String
  var summary: String
  var locked: Bool
  var redirect: Int
  var profession: PersonProfessionDTO

  var edit: PersonWikiEditDTO {
    PersonWikiEditDTO(
      name: name,
      infobox: infobox,
      summary: summary,
      profession: profession
    )
  }

  var expectedRevision: SimpleWikiExpectedDTO {
    SimpleWikiExpectedDTO(name: name, infobox: infobox, summary: summary)
  }
}

struct PersonWikiEditDTO: Codable, Hashable, Sendable {
  var name: String
  var infobox: String
  var summary: String
  var profession: PersonProfessionDTO
}

struct PersonWikiRevisionDTO: Codable, Hashable, Sendable {
  var name: String
  var infobox: String
  var summary: String
  var profession: PersonProfessionDTO
  var extra: WikiRevisionExtraDTO?
}

struct CharacterWikiInfoDTO: Codable, Hashable, Sendable, Identifiable {
  var id: Int
  var name: String
  var infobox: String
  var summary: String
  var locked: Bool
  var redirect: Int

  var edit: CharacterWikiEditDTO {
    CharacterWikiEditDTO(name: name, infobox: infobox, summary: summary)
  }

  var expectedRevision: SimpleWikiExpectedDTO {
    SimpleWikiExpectedDTO(name: name, infobox: infobox, summary: summary)
  }
}

struct CharacterWikiEditDTO: Codable, Hashable, Sendable {
  var name: String
  var infobox: String
  var summary: String
}

struct CharacterWikiRevisionDTO: Codable, Hashable, Sendable {
  var name: String
  var infobox: String
  var summary: String
  var extra: WikiRevisionExtraDTO?
}

struct SimpleWikiExpectedDTO: Codable, Hashable, Sendable {
  var name: String?
  var infobox: String?
  var summary: String?
}

struct WikiRevisionExtraDTO: Codable, Hashable, Sendable {
  var img: String?
}

struct EpisodeWikiInfoDTO: Codable, Hashable, Sendable, Identifiable {
  var id: Int
  var subjectID: Int
  var name: String
  var nameCN: String
  var ep: Double
  var disc: Double?
  var date: String?
  var type: EpisodeType
  var duration: String
  var summary: String

  var edit: EpisodeWikiEditDTO {
    EpisodeWikiEditDTO(
      id: id,
      subjectID: subjectID,
      name: name,
      nameCN: nameCN,
      ep: ep,
      disc: disc,
      date: date,
      type: type,
      duration: duration,
      summary: summary
    )
  }

  var expectedRevision: EpisodeWikiExpectedDTO {
    EpisodeWikiExpectedDTO(
      name: name,
      nameCN: nameCN,
      duration: duration,
      date: date,
      summary: summary
    )
  }
}

struct EpisodeWikiEditDTO: Codable, Hashable, Sendable {
  var id: Int?
  var subjectID: Int?
  var name: String?
  var nameCN: String?
  var ep: Double?
  var disc: Double?
  var date: String?
  var type: EpisodeType?
  var duration: String?
  var summary: String?
}

struct EpisodeWikiExpectedDTO: Codable, Hashable, Sendable {
  var name: String?
  var nameCN: String?
  var duration: String?
  var date: String?
  var summary: String?
}

struct WikiRevisionCreatorDTO: Codable, Hashable, Sendable {
  var username: String
  var nickname: String
}

struct WikiRevisionHistoryDTO: Codable, Identifiable, Hashable, Sendable {
  var id: Int
  var creator: WikiRevisionCreatorDTO
  var type: Int
  var commitMessage: String
  var createdAt: Int
}

struct WikiRecentItemDTO: Codable, Identifiable, Hashable, Sendable {
  var id: Int
  var createdAt: Int
}

struct SubjectRecentWikiDTO: Codable, Hashable, Sendable {
  var subject: [WikiRecentItemDTO]
  var persons: [WikiRecentItemDTO]
}

struct SubjectCoverListDTO: Codable, Hashable, Sendable {
  var current: SubjectCoverDTO?
  var covers: [SubjectCoverDTO]
}

struct SubjectCoverDTO: Codable, Identifiable, Hashable, Sendable {
  var id: Int
  var thumbnail: String
  var raw: String
  var creator: SlimUserDTO?
  var voted: Bool?
}

struct MonoPortraitResponseDTO: Codable, Hashable, Sendable {
  var img: String
}

struct SubjectCreateResponseDTO: Codable, Hashable, Sendable {
  var subjectID: Int
}

struct PersonCreateResponseDTO: Codable, Hashable, Sendable {
  var personID: Int
}

struct CharacterCreateResponseDTO: Codable, Hashable, Sendable {
  var characterID: Int
}

struct EpisodeCreateResponseDTO: Codable, Hashable, Sendable {
  var episodeIDs: [Int]
}

struct WikiSubjectContributionDTO: Codable, Identifiable, Hashable, Sendable {
  var id: Int
  var type: Int
  var subjectID: Int
  var name: String
  var commitMessage: String
  var createdAt: Int
}

struct WikiPersonContributionDTO: Codable, Identifiable, Hashable, Sendable {
  var id: Int
  var type: Int
  var personID: Int
  var name: String
  var commitMessage: String
  var createdAt: Int
}

struct WikiCharacterContributionDTO: Codable, Identifiable, Hashable, Sendable {
  var id: Int
  var type: Int
  var characterID: Int
  var name: String
  var commitMessage: String
  var createdAt: Int
}

struct WikiSimpleSubjectDTO: Codable, Hashable, Sendable, Identifiable {
  var id: Int
  var typeID: SubjectType
  var name: String
  var nameCN: String
}

struct WikiSimplePersonDTO: Codable, Hashable, Sendable, Identifiable {
  var id: Int
  var name: String
  var nameCN: String
}

struct WikiSimpleCharacterDTO: Codable, Hashable, Sendable, Identifiable {
  var id: Int
  var name: String
  var nameCN: String
}

struct SubjectRelationRevisionDTO: Codable, Identifiable, Hashable, Sendable {
  var subject: WikiSimpleSubjectDTO
  var type: Int
  var order: Int

  var id: String {
    "\(subject.id)-\(type)-\(order)"
  }
}

struct SubjectCharacterRevisionDTO: Codable, Identifiable, Hashable, Sendable {
  var character: WikiSimpleCharacterDTO
  var type: Int
  var order: Int

  var id: String {
    "\(character.id)-\(type)-\(order)"
  }
}

struct SubjectPersonRevisionDTO: Codable, Identifiable, Hashable, Sendable {
  var person: WikiSimplePersonDTO
  var position: Int

  var id: String {
    "\(person.id)-\(position)"
  }
}

struct PersonSubjectRevisionDTO: Codable, Identifiable, Hashable, Sendable {
  var subject: WikiSimpleSubjectDTO
  var position: Int

  var id: String {
    "\(subject.id)-\(position)"
  }
}

struct PersonCastRevisionDTO: Codable, Identifiable, Hashable, Sendable {
  var subject: WikiSimpleSubjectDTO
  var character: WikiSimpleCharacterDTO

  var id: String {
    "\(subject.id)-\(character.id)"
  }
}

struct CharacterSubjectRevisionDTO: Codable, Identifiable, Hashable, Sendable {
  var subject: WikiSimpleSubjectDTO
  var type: Int
  var order: Int

  var id: String {
    "\(subject.id)-\(type)-\(order)"
  }
}

struct CharacterCastRevisionDTO: Codable, Identifiable, Hashable, Sendable {
  var subject: WikiSimpleSubjectDTO
  var person: WikiSimplePersonDTO

  var id: String {
    "\(subject.id)-\(person.id)"
  }
}
