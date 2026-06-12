import Foundation
import SwiftData
import SwiftUI

struct SubjectDetailDTO: Hashable {
  var positions: [SubjectPositionDTO] = []
  var characters: [SubjectCharacterDTO] = []
  var offprints: [SubjectRelationDTO] = []
  var relations: [SubjectRelationDTO] = []
  var recs: [SubjectRecDTO] = []
  var collects: [SubjectCollectDTO] = []
  var reviews: [SubjectReviewDTO] = []
  var topics: [TopicDTO] = []
  var comments: [SubjectCommentDTO] = []
  var indexes: [SlimIndexDTO] = []
}

struct CharacterDetailDTO: Hashable {
  var casts: [CharacterCastDTO] = []
  var relations: [CharacterRelationDTO] = []
  var indexes: [SlimIndexDTO] = []
}

struct PersonDetailDTO: Hashable {
  var casts: [PersonCastDTO] = []
  var works: [PersonWorkDTO] = []
  var relations: [PersonRelationDTO] = []
  var indexes: [SlimIndexDTO] = []
}

struct GroupDetailDTO: Hashable {
  var moderators: [GroupMemberDTO] = []
  var recentMembers: [GroupMemberDTO] = []
  var recentTopics: [TopicDTO] = []
}

struct CalendarEntryDTO: Identifiable, Hashable {
  let weekday: Int
  var items: [BangumiCalendarItemDTO]

  var id: Int {
    weekday
  }
}

struct DraftDTO: Identifiable, Hashable {
  let id: PersistentIdentifier
  var type: String
  var content: String
  var createdAt: Int
  var updatedAt: Int
}

struct ProgressSubjectDTO: Identifiable, Hashable {
  var subject: SubjectDTO
  var episodes: [EpisodeDTO]

  var id: Int {
    subject.id
  }
}

extension SubjectInterest {
  var slim: SlimSubjectInterestDTO {
    SlimSubjectInterestDTO(
      rate: rate,
      type: type,
      comment: comment,
      tags: tags,
      updatedAt: updatedAt
    )
  }
}

extension SlimSubjectDTO {
  var ctypeEnum: CollectionType {
    interest?.type ?? .none
  }
}

extension SubjectDTO {
  init(_ subject: Subject) {
    id = subject.subjectId
    airtime = subject.airtime
    collection = subject.collection
    eps = subject.eps
    images = subject.images
    infobox = subject.infobox
    info = subject.info
    locked = subject.locked
    metaTags = subject.metaTags
    tags = subject.tags
    name = subject.name
    nameCN = subject.nameCN
    nsfw = subject.nsfw
    platform = subject.platform
    rating = subject.rating
    redirect = 0
    series = subject.series
    seriesEntry = 0
    summary = subject.summary
    type = subject.typeEnum
    volumes = subject.volumes
    interest = subject.interest
  }

  var ctypeEnum: CollectionType {
    interest?.type ?? .none
  }

  var collectedAt: Int {
    interest?.updatedAt ?? 0
  }

  var link: String {
    "chii://subject/\(id)"
  }

  var category: String {
    if platform.typeCN.isEmpty {
      return type.description
    }
    if series {
      return "\(platform.typeCN)系列"
    }
    return platform.typeCN
  }

  var epsDesc: String {
    eps > 0 ? "\(eps)" : "??"
  }

  var volumesDesc: String {
    volumes > 0 ? "\(volumes)" : "??"
  }

  func title(with preference: TitlePreference) -> String {
    preference.title(name: name, nameCN: nameCN)
  }

  func subtitle(with preference: TitlePreference) -> String? {
    switch preference {
    case .chinese:
      return nameCN.isEmpty ? nil : (name != nameCN ? name : nil)
    case .original:
      return name.isEmpty ? nil : (nameCN != name && !nameCN.isEmpty ? nameCN : nil)
    }
  }
}

extension EpisodeDTO {
  init(_ episode: Episode) {
    id = episode.episodeId
    subjectID = episode.subjectId
    type = episode.typeEnum
    sort = episode.sort
    name = episode.name
    nameCN = episode.nameCN
    duration = episode.duration
    airdate = episode.airdate
    comment = episode.comment
    disc = episode.disc
    desc = episode.desc
    collection = EpisodeCollectionStatus(
      status: episode.status,
      updatedAt: episode.collectedAt == 0 ? nil : episode.collectedAt
    )
    subject = episode.subject.map(SlimSubjectDTO.init)
  }

  var typeEnum: EpisodeType {
    type
  }

  var collectionTypeEnum: EpisodeCollectionType {
    EpisodeCollectionType(collection?.status ?? 0)
  }

  var status: Int {
    collection?.status ?? 0
  }

  var collectedAt: Int {
    collection?.updatedAt ?? 0
  }

  var air: Date {
    safeParseDate(str: airdate)
  }

  var aired: Bool {
    air < Date()
  }

  var waitDesc: String {
    if air.timeIntervalSince1970 == 0 {
      return "未知"
    }

    let calendar = Calendar.current
    let now = Date()
    let components = calendar.dateComponents([.day], from: now, to: air)

    if components.day == 0 {
      return "明天"
    }
    return "\(components.day ?? 0) 天后"
  }

  var borderColor: Color {
    var hex = 0x666666
    switch collectionTypeEnum {
    case .none:
      hex = aired ? 0x00A8FF : 0x909090
    case .wish:
      hex = 0xFF2293
    case .collect:
      hex = 0x1175A8
    case .dropped:
      hex = 0x666666
    }
    return Color(hex: hex)
  }

  var backgroundColor: Color {
    var hex = 0xCCCCCC
    switch collectionTypeEnum {
    case .none:
      hex = aired ? 0xDAEAFF : 0xE0E0E0
    case .wish:
      hex = 0xFFADD1
    case .collect:
      hex = 0x4897FF
    case .dropped:
      hex = 0xCCCCCC
    }
    return Color(hex: hex)
  }

  var textColor: Color {
    var hex = 0xFFFFFF
    switch collectionTypeEnum {
    case .none:
      hex = aired ? 0x0066CC : 0x909090
    case .wish:
      hex = 0xFF2293
    case .collect:
      hex = 0xFFFFFF
    case .dropped:
      hex = 0xFFFFFF
    }
    return Color(hex: hex)
  }

  var trendColor: Color {
    var opacity = 0.0
    if comment > 0 {
      opacity = 0.1 + 0.9 * (1.0 - exp(-Double(comment - 1) / 200.0))
    }
    return Color(hex: 0xFF8040, opacity: opacity)
  }

  func titleLink(with preference: TitlePreference) -> AttributedString {
    var text = AttributedString("\(type.name).\(sort.episodeDisplay) ")
    text.foregroundColor = .secondary
    text += preference.title(name: name, nameCN: nameCN).withLink(link)
    return text
  }
}

extension CharacterDTO {
  init(_ character: Character) {
    collects = character.collects
    comment = character.comment
    id = character.characterId
    images = character.images
    infobox = character.infobox
    info = character.info
    lock = character.lock
    name = character.name
    nameCN = character.nameCN
    nsfw = character.nsfw
    redirect = 0
    role = character.roleEnum
    summary = character.summary
    collectedAt = character.collectedAt
  }

  func title(with preference: TitlePreference) -> String {
    preference.title(name: name, nameCN: nameCN)
  }

  func subtitle(with preference: TitlePreference) -> String? {
    switch preference {
    case .chinese:
      return nameCN.isEmpty ? nil : (name != nameCN ? name : nil)
    case .original:
      return name.isEmpty ? nil : (nameCN != name && !nameCN.isEmpty ? nameCN : nil)
    }
  }
}

extension PersonDTO {
  init(_ person: Person) {
    career = person.career.compactMap { PersonCareer(rawValue: $0) }
    collects = person.collects
    comment = person.comment
    id = person.personId
    images = person.images
    infobox = person.infobox
    info = person.info
    lock = person.lock
    name = person.name
    nameCN = person.nameCN
    nsfw = person.nsfw
    redirect = 0
    summary = person.summary
    type = person.typeEnum
    collectedAt = person.collectedAt
  }

  func title(with preference: TitlePreference) -> String {
    preference.title(name: name, nameCN: nameCN)
  }

  func subtitle(with preference: TitlePreference) -> String? {
    switch preference {
    case .chinese:
      return nameCN.isEmpty ? nil : (name != nameCN ? name : nil)
    case .original:
      return name.isEmpty ? nil : (nameCN != name && !nameCN.isEmpty ? nameCN : nil)
    }
  }
}

extension GroupDTO {
  init(_ group: ChiiGroup) {
    id = group.groupId
    name = group.name
    nsfw = group.nsfw
    title = group.title
    icon = group.icon
    creator = group.creator
    creatorID = group.creatorID
    description = group.desc
    cat = group.cat
    accessible = group.accessible
    members = group.members
    posts = group.posts
    topics = group.topics
    createdAt = group.createdAt
    membership = GroupMemberDTO(
      user: nil,
      uid: 0,
      role: group.memberRole,
      joinedAt: group.joinedAt
    )
  }

  var slim: SlimGroupDTO {
    SlimGroupDTO(
      id: id,
      name: name,
      nsfw: nsfw,
      title: title,
      icon: icon,
      creatorID: creatorID,
      members: members,
      createdAt: createdAt,
      accessible: accessible
    )
  }

  var memberRole: GroupMemberRole {
    membership?.role ?? .guest
  }

  var joinedAt: Int {
    membership?.joinedAt ?? 0
  }

  var canCreateTopic: Bool {
    if accessible {
      return true
    }
    switch memberRole {
    case .member, .moderator, .creator:
      return true
    default:
      return false
    }
  }
}

extension UserDTO {
  init(_ user: User) {
    id = user.userId
    username = user.username
    nickname = user.nickname
    avatar = user.avatar
    group = user.groupEnum
    joinedAt = user.joinedAt
    sign = user.sign
    site = user.site
    location = user.location
    bio = user.bio
    networkServices = user.networkServices
    homepage = user.homepage
    stats =
      user.stats
      ?? UserStatsDTO(
        subject: [:],
        mono: UserMonoCollectionStatsDTO(character: 0, person: 0),
        blog: 0,
        friend: 0,
        group: 0,
        index: UserIndexStatsDTO(create: 0, collect: 0)
      )
  }
}

extension DraftDTO {
  init(_ draft: Draft) {
    id = draft.persistentModelID
    type = draft.type
    content = draft.content
    createdAt = draft.createdAt
    updatedAt = draft.updatedAt
  }
}
