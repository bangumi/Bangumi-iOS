import Foundation
import SwiftData

enum BangumiSchemaV2: VersionedSchema {
    static var versionIdentifier: Schema.Version {
        Schema.Version(2, 0, 0)
    }

    static var models: [any PersistentModel.Type] {
        [
            BangumiSchemaV2.SubjectV2.self,
            BangumiSchemaV2.EpisodeV2.self,
            BangumiSchemaV2.CharacterV2.self,
            BangumiSchemaV2.PersonV2.self,
            BangumiSchemaV2.GroupV2.self,
            BangumiSchemaV2.UserV1.self,
            BangumiSchemaV2.DraftV1.self,
            BangumiSchemaV2.TrendingSubjectV1.self,
            BangumiSchemaV2.BangumiCalendarV1.self,
            BangumiSchemaV2.SubjectDetailV1.self,
            BangumiSchemaV2.RakuenSubjectTopicCacheV1.self,
            BangumiSchemaV2.RakuenGroupTopicCacheV1.self,
            BangumiSchemaV2.RakuenGroupCacheV1.self,
        ]
    }

    // MARK: - SubjectV2

    @Model
    final class SubjectV2: Searchable, Linkable {
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
        var detail: SubjectDetail?

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
    }

    // MARK: - EpisodeV2

    @Model
    final class EpisodeV2: Linkable {
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

        var subject: Subject?

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
    }

    // MARK: - CharacterV2

    @Model
    final class CharacterV2: Searchable, Linkable {
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

        var casts: [CharacterCastDTO] = []
        var relations: [CharacterRelationDTO] = []
        var indexes: [SlimIndexDTO] = []

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
    }

    // MARK: - PersonV2

    @Model
    final class PersonV2: Searchable, Linkable {
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

        var casts: [PersonCastDTO] = []
        var works: [PersonWorkDTO] = []
        var relations: [PersonRelationDTO] = []
        var indexes: [SlimIndexDTO] = []

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
    }

    // MARK: - GroupV2

    @Model
    final class GroupV2: Linkable {
        @Attribute(.unique)
        var groupId: Int

        var name: String
        var nsfw: Bool
        var title: String
        var icon: Avatar?
        var creator: SlimUserDTO?
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
        var moderators: [GroupMemberDTO] = []
        var recentMembers: [GroupMemberDTO] = []
        var recentTopics: [TopicDTO] = []

        init(_ item: GroupDTO) {
            self.groupId = item.id
            self.name = item.name
            self.nsfw = item.nsfw
            self.title = item.title
            self.icon = item.icon
            self.creator = item.creator
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
    }

    // MARK: - UserV1

    @Model
    final class UserV1 {
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
        var networkServices: [UserNetworkServiceDTO]
        var homepage: UserHomepageDTO
        var stats: UserStatsDTO?

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
            self.networkServices = item.networkServices
            self.homepage = item.homepage
            self.stats = item.stats
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

    // MARK: - TrendingSubjectV1

    @Model
    final class TrendingSubjectV1 {
        @Attribute(.unique)
        var type: Int

        var items: [TrendingSubjectDTO]

        init(type: Int, items: [TrendingSubjectDTO]) {
            self.type = type
            self.items = items
        }
    }

    // MARK: - BangumiCalendarV1

    @Model
    final class BangumiCalendarV1 {
        @Attribute(.unique)
        var weekday: Int

        var items: [BangumiCalendarItemDTO]

        init(weekday: Int, items: [BangumiCalendarItemDTO]) {
            self.weekday = weekday
            self.items = items
        }
    }

    // MARK: - SubjectDetailV1

    @Model
    final class SubjectDetailV1 {
        @Attribute(.unique)
        var subjectId: Int

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

        init(subjectId: Int) {
            self.subjectId = subjectId
        }
    }

    // MARK: - RakuenSubjectTopicCacheV1

    @Model
    final class RakuenSubjectTopicCacheV1 {
        @Attribute(.unique)
        var mode: String

        var items: [SubjectTopicDTO]
        var updatedAt: Date

        init(mode: String, items: [SubjectTopicDTO]) {
            self.mode = mode
            self.items = items
            self.updatedAt = Date()
        }
    }

    // MARK: - RakuenGroupTopicCacheV1

    @Model
    final class RakuenGroupTopicCacheV1 {
        @Attribute(.unique)
        var mode: String

        var items: [GroupTopicDTO]
        var updatedAt: Date

        init(mode: String, items: [GroupTopicDTO]) {
            self.mode = mode
            self.items = items
            self.updatedAt = Date()
        }
    }

    // MARK: - RakuenGroupCacheV1

    @Model
    final class RakuenGroupCacheV1 {
        @Attribute(.unique)
        var id: String

        var items: [SlimGroupDTO]
        var updatedAt: Date

        init(id: String, items: [SlimGroupDTO]) {
            self.id = id
            self.items = items
            self.updatedAt = Date()
        }
    }
}
