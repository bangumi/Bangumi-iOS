import Foundation
import GRDB

enum DatabaseRecordCoding {
  static func encode<Value: Encodable>(_ value: Value) -> Data? {
    PersistedJSON.encode(value)
  }

  static func encode<Value: Encodable>(_ value: Value?) -> Data? {
    guard let value else {
      return nil
    }
    return PersistedJSON.encode(value)
  }

  static func decode<Value: Decodable>(
    _ type: Value.Type,
    from data: Data?,
    fallback: @autoclosure () -> Value
  ) -> Value {
    PersistedJSON.decode(type, from: data) ?? fallback()
  }

  static func bool(_ value: Bool) -> Int {
    value ? 1 : 0
  }

  static func bool(_ value: Int) -> Bool {
    value != 0
  }

  static var emptyUserStats: UserStatsDTO {
    UserStatsDTO(
      subject: [:],
      mono: UserMonoCollectionStatsDTO(character: 0, person: 0),
      blog: 0,
      friend: 0,
      group: 0,
      index: UserIndexStatsDTO(create: 0, collect: 0)
    )
  }
}

extension Row {
  fileprivate func json<Value: Decodable>(
    _ type: Value.Type,
    _ column: String,
    fallback: @autoclosure () -> Value
  ) -> Value {
    let data: Data? = self[column]
    return DatabaseRecordCoding.decode(type, from: data, fallback: fallback())
  }

  fileprivate func jsonOptional<Value: Decodable>(_ type: Value.Type, _ column: String) -> Value? {
    let data: Data? = self[column]
    return PersistedJSON.decode(type, from: data)
  }
}

extension Subject {
  convenience init(row: Row, detail: SubjectDetail? = nil) {
    let typeValue: Int = row["type"]
    let interest: SubjectInterest? = row.jsonOptional(SubjectInterest.self, "interest_data")
    self.init(
      SubjectDTO(
        id: row["subject_id"],
        airtime: row.json(SubjectAirtime.self, "airtime_data", fallback: SubjectAirtime(date: "")),
        collection: row.json(SubjectCollection.self, "collection_data", fallback: [:]),
        eps: row["eps"],
        images: row.jsonOptional(SubjectImages.self, "images_data"),
        infobox: row.json(Infobox.self, "infobox_data", fallback: []),
        info: row["info"],
        locked: DatabaseRecordCoding.bool(row["locked"] as Int),
        metaTags: row.json([String].self, "meta_tags_data", fallback: []),
        tags: row.json([Tag].self, "tags_data", fallback: []),
        name: row["name"],
        nameCN: row["name_cn"],
        nsfw: DatabaseRecordCoding.bool(row["nsfw"] as Int),
        platform: row.json(
          SubjectPlatform.self, "platform_data", fallback: SubjectPlatform(name: "")),
        rating: row.json(SubjectRating.self, "rating_data", fallback: SubjectRating()),
        redirect: 0,
        series: DatabaseRecordCoding.bool(row["series"] as Int),
        seriesEntry: 0,
        summary: row["summary"],
        type: SubjectType(typeValue),
        volumes: row["volumes"],
        interest: interest
      )
    )
    ctype = row["ctype"]
    collectedAt = row["collected_at"]
    alias = row["alias"]
    self.detail = detail
  }
}

extension Episode {
  convenience init(row: Row, subject: Subject? = nil) {
    let typeValue: Int = row["type"]
    let sortValue: Double = row["sort"]
    let collectedAt: Int = row["collected_at"]
    self.init(
      EpisodeDTO(
        id: row["episode_id"],
        subjectID: row["subject_id"],
        type: EpisodeType(typeValue),
        sort: Float(sortValue),
        name: row["name"],
        nameCN: row["name_cn"],
        duration: row["duration"],
        airdate: row["airdate"],
        comment: row["comment"],
        disc: row["disc"],
        desc: row["desc"],
        collection: EpisodeCollectionStatus(
          status: row["status"],
          updatedAt: collectedAt == 0 ? nil : collectedAt
        ),
        subject: subject.map(SlimSubjectDTO.init)
      )
    )
    self.subject = subject
  }
}

extension Character {
  convenience init(row: Row) {
    let roleValue: Int = row["role"]
    self.init(
      CharacterDTO(
        collects: row["collects"],
        comment: row["comment"],
        id: row["character_id"],
        images: row.jsonOptional(Images.self, "images_data"),
        infobox: row.json(Infobox.self, "infobox_data", fallback: []),
        info: row["info"],
        lock: DatabaseRecordCoding.bool(row["lock"] as Int),
        name: row["name"],
        nameCN: row["name_cn"],
        nsfw: DatabaseRecordCoding.bool(row["nsfw"] as Int),
        redirect: 0,
        role: CharacterType(roleValue),
        summary: row["summary"],
        collectedAt: row["collected_at"]
      )
    )
    alias = row["alias"]
    castsData = row["casts_data"]
    relationsData = row["relations_data"]
    indexesData = row["indexes_data"]
  }
}

extension Person {
  convenience init(row: Row) {
    let typeValue: Int = row["type"]
    let careers = row.json([String].self, "career_data", fallback: [])
      .compactMap(PersonCareer.init(rawValue:))
    self.init(
      PersonDTO(
        career: careers,
        collects: row["collects"],
        comment: row["comment"],
        id: row["person_id"],
        images: row.jsonOptional(Images.self, "images_data"),
        infobox: row.json(Infobox.self, "infobox_data", fallback: []),
        info: row["info"],
        lock: DatabaseRecordCoding.bool(row["lock"] as Int),
        name: row["name"],
        nameCN: row["name_cn"],
        nsfw: DatabaseRecordCoding.bool(row["nsfw"] as Int),
        redirect: 0,
        summary: row["summary"],
        type: PersonType(typeValue),
        collectedAt: row["collected_at"]
      )
    )
    alias = row["alias"]
    castsData = row["casts_data"]
    worksData = row["works_data"]
    relationsData = row["relations_data"]
    indexesData = row["indexes_data"]
  }
}

extension ChiiGroup {
  convenience init(row: Row) {
    let roleValue: Int = row["role"]
    self.init(
      GroupDTO(
        id: row["group_id"],
        name: row["name"],
        nsfw: DatabaseRecordCoding.bool(row["nsfw"] as Int),
        title: row["title"],
        icon: row.jsonOptional(Avatar.self, "icon_data"),
        creator: row.jsonOptional(SlimUserDTO.self, "creator_data"),
        creatorID: row["creator_id"],
        description: row["desc"],
        cat: row["cat"],
        accessible: DatabaseRecordCoding.bool(row["accessible"] as Int),
        members: row["members"],
        posts: row["posts"],
        topics: row["topics"],
        createdAt: row["created_at"],
        membership: GroupMemberDTO(
          user: nil,
          uid: 0,
          role: GroupMemberRole(rawValue: roleValue),
          joinedAt: row["joined_at"]
        )
      )
    )
    moderatorsData = row["moderators_data"]
    recentMembersData = row["recent_members_data"]
    recentTopicsData = row["recent_topics_data"]
  }
}

extension User {
  convenience init(row: Row) {
    let groupValue: Int = row["group_value"]
    self.init(
      UserDTO(
        id: row["user_id"],
        username: row["username"],
        nickname: row["nickname"],
        avatar: row.jsonOptional(Avatar.self, "avatar_data"),
        group: UserGroup(groupValue),
        joinedAt: row["joined_at"],
        sign: row["sign"],
        site: row["site"],
        location: row["location"],
        bio: row["bio"],
        networkServices: row.json(
          [UserNetworkServiceDTO].self,
          "network_services_data",
          fallback: []
        ),
        homepage: row.json(
          UserHomepageDTO.self,
          "homepage_data",
          fallback: UserHomepageDTO(left: [], right: [])
        ),
        stats: row.json(
          UserStatsDTO.self,
          "stats_data",
          fallback: DatabaseRecordCoding.emptyUserStats
        )
      )
    )
  }
}

extension Draft {
  convenience init(row: Row) {
    self.init(
      draftId: row["draft_id"],
      type: row["type"],
      content: row["content"]
    )
    createdAt = row["created_at"]
    updatedAt = row["updated_at"]
  }
}

extension TrendingSubject {
  convenience init(row: Row) {
    self.init(
      type: row["type"],
      items: row.json([TrendingSubjectDTO].self, "items_data", fallback: [])
    )
  }
}

extension BangumiCalendar {
  convenience init(row: Row) {
    self.init(
      weekday: row["weekday"],
      items: row.json([BangumiCalendarItemDTO].self, "items_data", fallback: [])
    )
  }
}

extension SubjectDetail {
  convenience init(row: Row) {
    self.init(subjectId: row["subject_id"])
    positionsData = row["positions_data"]
    charactersData = row["characters_data"]
    offprintsData = row["offprints_data"]
    relationsData = row["relations_data"]
    recsData = row["recs_data"]
    collectsData = row["collects_data"]
    reviewsData = row["reviews_data"]
    topicsData = row["topics_data"]
    commentsData = row["comments_data"]
    indexesData = row["indexes_data"]
  }
}

extension RakuenSubjectTopicCache {
  convenience init(row: Row) {
    self.init(
      mode: row["mode"],
      items: row.json([SubjectTopicDTO].self, "items_data", fallback: [])
    )
    let updatedAtValue: Double = row["updated_at"]
    updatedAt = Date(timeIntervalSince1970: updatedAtValue)
  }
}

extension RakuenGroupTopicCache {
  convenience init(row: Row) {
    self.init(
      mode: row["mode"],
      items: row.json([GroupTopicDTO].self, "items_data", fallback: [])
    )
    let updatedAtValue: Double = row["updated_at"]
    updatedAt = Date(timeIntervalSince1970: updatedAtValue)
  }
}

extension RakuenGroupCache {
  convenience init(row: Row) {
    self.init(
      id: row["id"],
      items: row.json([SlimGroupDTO].self, "items_data", fallback: [])
    )
    let updatedAtValue: Double = row["updated_at"]
    updatedAt = Date(timeIntervalSince1970: updatedAtValue)
  }
}
