import Foundation
import SwiftData

enum BangumiSchemaV3: VersionedSchema {
  static var versionIdentifier: Schema.Version {
    Schema.Version(3, 0, 0)
  }

  static var models: [any PersistentModel.Type] {
    [
      BangumiSchemaV3.SubjectV3.self,
      BangumiSchemaV3.EpisodeV3.self,
      BangumiSchemaV3.CharacterV3.self,
      BangumiSchemaV3.PersonV3.self,
      BangumiSchemaV3.GroupV3.self,
      BangumiSchemaV3.UserV2.self,
      BangumiSchemaV3.DraftV1.self,
      BangumiSchemaV3.TrendingSubjectV2.self,
      BangumiSchemaV3.BangumiCalendarV2.self,
      BangumiSchemaV3.SubjectDetailV2.self,
      BangumiSchemaV3.RakuenSubjectTopicCacheV2.self,
      BangumiSchemaV3.RakuenGroupTopicCacheV2.self,
      BangumiSchemaV3.RakuenGroupCacheV2.self,
    ]
  }

  // MARK: - SubjectV3

  @Model
  final class SubjectV3: Searchable, Linkable {
    @Attribute(.unique)
    var subjectId: Int

    var airtime: SubjectAirtime
    var collection: SubjectCollection
    var eps: Int
    var images: SubjectImages?
    var infobox: Infobox
    var locked: Bool
    var metaTags: [String]
    var tags: [Tag]
    var name: String
    var nameCN: String
    var nsfw: Bool
    var platform: SubjectPlatform
    var rating: SubjectRating
    var series: Bool
    var summary: String
    var type: Int
    var volumes: Int
    var info: String = ""
    var alias: String = ""

    var ctype: Int = 0
    var collectedAt: Int = 0
    var interest: SubjectInterest?

    @Relationship(deleteRule: .cascade)
    var detail: BangumiSchemaV3.SubjectDetailV2?

    init(_ item: SubjectDTO) {
      self.subjectId = item.id
      self.airtime = item.airtime
      self.collection = item.collection
      self.eps = item.eps
      self.images = item.images
      self.infobox = item.infobox.clean()
      self.info = item.info
      self.locked = item.locked
      self.metaTags = item.metaTags
      self.tags = item.tags
      self.name = item.name
      self.nameCN = item.nameCN
      self.nsfw = item.nsfw
      self.platform = item.platform
      self.rating = item.rating
      self.series = item.series
      self.summary = item.summary
      self.type = item.type.rawValue
      self.volumes = item.volumes
      self.interest = item.interest
      if let interest = item.interest {
        self.ctype = interest.type.rawValue
        self.collectedAt = interest.updatedAt
      }
      self.alias = item.infobox.aliases.joined(separator: " ")
    }

    init(_ item: SlimSubjectDTO) {
      self.subjectId = item.id
      self.airtime = SubjectAirtime(date: "")
      self.collection = [:]
      self.eps = 0
      self.images = item.images
      self.infobox = []
      self.info = item.info ?? ""
      self.locked = item.locked
      self.metaTags = []
      self.tags = []
      self.name = item.name
      self.nameCN = item.nameCN
      self.nsfw = item.nsfw
      self.platform = SubjectPlatform(name: "")
      self.rating = item.rating ?? SubjectRating()
      self.series = false
      self.summary = ""
      self.type = item.type.rawValue
      self.volumes = 0
      self.alias = ""
      self.interest = nil
    }

    init(_ snapshot: SubjectSnapshot) {
      self.subjectId = snapshot.subjectId
      self.airtime = snapshot.airtime
      self.collection = snapshot.collection
      self.eps = snapshot.eps
      self.images = snapshot.images
      self.infobox = snapshot.infobox
      self.locked = snapshot.locked
      self.metaTags = snapshot.metaTags
      self.tags = snapshot.tags
      self.name = snapshot.name
      self.nameCN = snapshot.nameCN
      self.nsfw = snapshot.nsfw
      self.platform = snapshot.platform
      self.rating = snapshot.rating
      self.series = snapshot.series
      self.summary = snapshot.summary
      self.type = snapshot.type
      self.volumes = snapshot.volumes
      self.info = snapshot.info
      self.alias = snapshot.alias
      self.ctype = snapshot.ctype
      self.collectedAt = snapshot.collectedAt
      self.interest = snapshot.interest
    }
  }

  // MARK: - EpisodeV3

  @Model
  final class EpisodeV3: Linkable {
    @Attribute(.unique)
    var episodeId: Int

    var subjectId: Int
    var type: Int
    var sort: Float
    var name: String
    var nameCN: String
    var duration: String
    var airdate: String
    var comment: Int
    var desc: String
    var disc: Int

    var status: Int = 0
    var collectedAt: Int = 0

    var subject: BangumiSchemaV3.SubjectV3?

    init(_ item: EpisodeDTO) {
      self.episodeId = item.id
      self.subjectId = item.subjectID
      self.type = item.type.rawValue
      self.sort = item.sort
      self.name = item.name
      self.nameCN = item.nameCN
      self.duration = item.duration
      self.airdate = item.airdate
      self.comment = item.comment
      self.desc = item.desc ?? ""
      self.disc = item.disc
      if let collection = item.collection {
        self.status = collection.status
        self.collectedAt = collection.updatedAt ?? 0
      }
    }

    init(_ snapshot: EpisodeSnapshot) {
      self.episodeId = snapshot.episodeId
      self.subjectId = snapshot.subjectId
      self.type = snapshot.type
      self.sort = snapshot.sort
      self.name = snapshot.name
      self.nameCN = snapshot.nameCN
      self.duration = snapshot.duration
      self.airdate = snapshot.airdate
      self.comment = snapshot.comment
      self.desc = snapshot.desc
      self.disc = snapshot.disc
      self.status = snapshot.status
      self.collectedAt = snapshot.collectedAt
    }
  }

  // MARK: - CharacterV3

  @Model
  final class CharacterV3: Searchable, Linkable {
    @Attribute(.unique)
    var characterId: Int

    var collects: Int
    var comment: Int
    var images: Images?
    var infobox: Infobox
    var lock: Bool
    var name: String
    var nameCN: String
    var nsfw: Bool
    var role: Int
    var summary: String
    var info: String = ""
    var alias: String = ""

    var collectedAt: Int = 0

    var castsData: Data?
    var relationsData: Data?
    var indexesData: Data?

    init(_ item: CharacterDTO) {
      self.characterId = item.id
      self.collects = item.collects
      self.comment = item.comment
      self.images = item.images
      self.infobox = item.infobox.clean()
      self.lock = item.lock
      self.name = item.name
      self.nameCN = item.nameCN
      self.nsfw = item.nsfw
      self.role = item.role.rawValue
      self.summary = item.summary
      self.info = item.info
      self.alias = item.infobox.aliases.joined(separator: " ")
      self.collectedAt = item.collectedAt ?? 0
    }

    init(_ item: SlimCharacterDTO) {
      self.characterId = item.id
      self.collects = 0
      self.comment = item.comment ?? 0
      self.images = item.images
      self.infobox = []
      self.lock = item.lock
      self.name = item.name
      self.nameCN = item.nameCN
      self.nsfw = item.nsfw
      self.role = item.role.rawValue
      self.info = item.info ?? ""
      self.summary = ""
      self.alias = ""
      self.collectedAt = 0
    }

    init(_ snapshot: CharacterSnapshot) {
      self.characterId = snapshot.characterId
      self.collects = snapshot.collects
      self.comment = snapshot.comment
      self.images = snapshot.images
      self.infobox = snapshot.infobox
      self.lock = snapshot.lock
      self.name = snapshot.name
      self.nameCN = snapshot.nameCN
      self.nsfw = snapshot.nsfw
      self.role = snapshot.role
      self.summary = snapshot.summary
      self.info = snapshot.info
      self.alias = snapshot.alias
      self.collectedAt = snapshot.collectedAt
    }
  }

  // MARK: - PersonV3

  @Model
  final class PersonV3: Searchable, Linkable {
    @Attribute(.unique)
    var personId: Int

    var career: [String]
    var collects: Int
    var comment: Int
    var images: Images?
    var infobox: Infobox
    var lock: Bool
    var name: String
    var nameCN: String
    var nsfw: Bool
    var summary: String
    var type: Int
    var info: String = ""
    var alias: String = ""

    var collectedAt: Int = 0

    var castsData: Data?
    var worksData: Data?
    var relationsData: Data?
    var indexesData: Data?

    init(_ item: PersonDTO) {
      self.personId = item.id
      self.career = item.career.map(\.rawValue)
      self.collects = item.collects
      self.comment = item.comment
      self.images = item.images
      self.infobox = item.infobox.clean()
      self.lock = item.lock
      self.name = item.name
      self.nameCN = item.nameCN
      self.nsfw = item.nsfw
      self.summary = item.summary
      self.type = item.type.rawValue
      self.info = item.info
      self.alias = item.infobox.aliases.joined(separator: " ")
      self.collectedAt = item.collectedAt ?? 0
    }

    init(_ item: SlimPersonDTO) {
      self.personId = item.id
      self.career = []
      self.collects = 0
      self.comment = item.comment ?? 0
      self.images = item.images
      self.infobox = []
      self.lock = item.lock
      self.name = item.name
      self.nameCN = item.nameCN
      self.nsfw = item.nsfw
      self.summary = ""
      self.info = item.info ?? ""
      self.type = item.type.rawValue
      self.alias = ""
      self.collectedAt = 0
    }

    init(_ snapshot: PersonSnapshot) {
      self.personId = snapshot.personId
      self.career = snapshot.career
      self.collects = snapshot.collects
      self.comment = snapshot.comment
      self.images = snapshot.images
      self.infobox = snapshot.infobox
      self.lock = snapshot.lock
      self.name = snapshot.name
      self.nameCN = snapshot.nameCN
      self.nsfw = snapshot.nsfw
      self.summary = snapshot.summary
      self.type = snapshot.type
      self.info = snapshot.info
      self.alias = snapshot.alias
      self.collectedAt = snapshot.collectedAt
    }
  }

  // MARK: - GroupV3

  @Model
  final class GroupV3: Linkable {
    @Attribute(.unique)
    var groupId: Int

    var name: String
    var nsfw: Bool
    var title: String
    var icon: Avatar?
    var creatorData: Data?
    var creatorID: Int
    var desc: String
    var cat: Int
    var accessible: Bool
    var members: Int
    var posts: Int
    var topics: Int
    var createdAt: Int

    /// membership
    var role: Int = -1
    var joinedAt: Int = 0

    /// details
    var moderatorsData: Data?
    var recentMembersData: Data?
    var recentTopicsData: Data?

    init(_ item: GroupDTO) {
      self.groupId = item.id
      self.name = item.name
      self.nsfw = item.nsfw
      self.title = item.title
      self.icon = item.icon
      self.creatorData = PersistedJSON.encode(item.creator)
      self.creatorID = item.creatorID
      self.desc = item.description
      self.cat = item.cat
      self.accessible = item.accessible
      self.members = item.members
      self.posts = item.posts
      self.topics = item.topics
      self.createdAt = item.createdAt
      self.role = item.membership?.role?.rawValue ?? -1
      self.joinedAt = item.membership?.joinedAt ?? 0
    }

    init(_ snapshot: GroupSnapshot) {
      self.groupId = snapshot.groupId
      self.name = snapshot.name
      self.nsfw = snapshot.nsfw
      self.title = snapshot.title
      self.icon = snapshot.icon
      self.creatorData = nil
      self.creatorID = snapshot.creatorID
      self.desc = snapshot.desc
      self.cat = snapshot.cat
      self.accessible = snapshot.accessible
      self.members = snapshot.members
      self.posts = snapshot.posts
      self.topics = snapshot.topics
      self.createdAt = snapshot.createdAt
      self.role = snapshot.role
      self.joinedAt = snapshot.joinedAt
    }
  }

  // MARK: - UserV2

  @Model
  final class UserV2 {
    @Attribute(.unique)
    var userId: Int

    var username: String
    var nickname: String
    var avatar: Avatar?
    var group: Int
    var joinedAt: Int
    var sign: String
    var site: String
    var location: String
    var bio: String
    var networkServicesData: Data?
    var homepageData: Data?
    var statsData: Data?

    init(_ item: UserDTO) {
      self.userId = item.id
      self.username = item.username
      self.nickname = item.nickname
      self.avatar = item.avatar
      self.group = item.group.rawValue
      self.joinedAt = item.joinedAt
      self.sign = item.sign
      self.site = item.site
      self.location = item.location
      self.bio = item.bio
      self.networkServicesData = PersistedJSON.encode(item.networkServices)
      self.homepageData = PersistedJSON.encode(item.homepage)
      self.statsData = PersistedJSON.encode(item.stats)
    }

    init(_ snapshot: UserSnapshot) {
      self.userId = snapshot.userId
      self.username = snapshot.username
      self.nickname = snapshot.nickname
      self.avatar = snapshot.avatar
      self.group = snapshot.group
      self.joinedAt = snapshot.joinedAt
      self.sign = snapshot.sign
      self.site = snapshot.site
      self.location = snapshot.location
      self.bio = snapshot.bio
      self.networkServicesData = nil
      self.homepageData = nil
      self.statsData = nil
    }
  }

  // MARK: - DraftV1

  @Model
  final class DraftV1 {
    var content: String
    var type: String
    var createdAt: Int
    var updatedAt: Int

    init(type: String, content: String) {
      self.content = content
      self.type = type
      self.createdAt = Int(Date().timeIntervalSince1970)
      self.updatedAt = Int(Date().timeIntervalSince1970)
    }
  }

  // MARK: - TrendingSubjectV2

  @Model
  final class TrendingSubjectV2 {
    @Attribute(.unique)
    var type: Int

    var itemsData: Data?

    init(type: Int, items: [TrendingSubjectDTO]) {
      self.type = type
      self.itemsData = PersistedJSON.encode(items)
    }
  }

  // MARK: - BangumiCalendarV2

  @Model
  final class BangumiCalendarV2 {
    @Attribute(.unique)
    var weekday: Int

    var itemsData: Data?

    init(weekday: Int, items: [BangumiCalendarItemDTO]) {
      self.weekday = weekday
      self.itemsData = PersistedJSON.encode(items)
    }
  }

  // MARK: - SubjectDetailV2

  @Model
  final class SubjectDetailV2 {
    @Attribute(.unique)
    var subjectId: Int

    var positionsData: Data?
    var charactersData: Data?
    var offprintsData: Data?
    var relationsData: Data?
    var recsData: Data?
    var collectsData: Data?
    var reviewsData: Data?
    var topicsData: Data?
    var commentsData: Data?
    var indexesData: Data?

    init(subjectId: Int) {
      self.subjectId = subjectId
    }
  }

  // MARK: - RakuenSubjectTopicCacheV2

  @Model
  final class RakuenSubjectTopicCacheV2 {
    @Attribute(.unique)
    var mode: String

    var itemsData: Data?
    var updatedAt: Date

    init(mode: String, items: [SubjectTopicDTO]) {
      self.mode = mode
      self.itemsData = PersistedJSON.encode(items)
      self.updatedAt = Date()
    }
  }

  // MARK: - RakuenGroupTopicCacheV2

  @Model
  final class RakuenGroupTopicCacheV2 {
    @Attribute(.unique)
    var mode: String

    var itemsData: Data?
    var updatedAt: Date

    init(mode: String, items: [GroupTopicDTO]) {
      self.mode = mode
      self.itemsData = PersistedJSON.encode(items)
      self.updatedAt = Date()
    }
  }

  // MARK: - RakuenGroupCacheV2

  @Model
  final class RakuenGroupCacheV2 {
    @Attribute(.unique)
    var id: String

    var itemsData: Data?
    var updatedAt: Date

    init(id: String, items: [SlimGroupDTO]) {
      self.id = id
      self.itemsData = PersistedJSON.encode(items)
      self.updatedAt = Date()
    }
  }
}
