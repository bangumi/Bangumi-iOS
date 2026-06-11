import Foundation

struct SubjectSnapshot: Codable {
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
  var info: String
  var alias: String
  var ctype: Int
  var collectedAt: Int
  var interest: SubjectInterest?

  init(_ subject: BangumiSchemaV2.SubjectV2) {
    subjectId = subject.subjectId
    airtime = subject.airtime
    collection = subject.collection
    eps = subject.eps
    images = subject.images
    infobox = subject.infobox
    locked = subject.locked
    metaTags = subject.metaTags
    tags = subject.tags
    name = subject.name
    nameCN = subject.nameCN
    nsfw = subject.nsfw
    platform = subject.platform
    rating = subject.rating
    series = subject.series
    summary = subject.summary
    type = subject.type
    volumes = subject.volumes
    info = subject.info
    alias = subject.alias
    ctype = subject.ctype
    collectedAt = subject.collectedAt
    interest = subject.interest
  }
}

struct EpisodeSnapshot: Codable {
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
  var status: Int
  var collectedAt: Int

  init(_ episode: BangumiSchemaV2.EpisodeV2) {
    episodeId = episode.episodeId
    subjectId = episode.subjectId
    type = episode.type
    sort = episode.sort
    name = episode.name
    nameCN = episode.nameCN
    duration = episode.duration
    airdate = episode.airdate
    comment = episode.comment
    desc = episode.desc
    disc = episode.disc
    status = episode.status
    collectedAt = episode.collectedAt
  }
}

struct CharacterSnapshot: Codable {
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
  var info: String
  var alias: String
  var collectedAt: Int

  init(_ character: BangumiSchemaV2.CharacterV2) {
    characterId = character.characterId
    collects = character.collects
    comment = character.comment
    images = character.images
    infobox = character.infobox
    lock = character.lock
    name = character.name
    nameCN = character.nameCN
    nsfw = character.nsfw
    role = character.role
    summary = character.summary
    info = character.info
    alias = character.alias
    collectedAt = character.collectedAt
  }
}

struct PersonSnapshot: Codable {
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
  var info: String
  var alias: String
  var collectedAt: Int

  init(_ person: BangumiSchemaV2.PersonV2) {
    personId = person.personId
    career = person.career
    collects = person.collects
    comment = person.comment
    images = person.images
    infobox = person.infobox
    lock = person.lock
    name = person.name
    nameCN = person.nameCN
    nsfw = person.nsfw
    summary = person.summary
    type = person.type
    info = person.info
    alias = person.alias
    collectedAt = person.collectedAt
  }
}

struct GroupSnapshot: Codable {
  var groupId: Int
  var name: String
  var nsfw: Bool
  var title: String
  var icon: Avatar?
  var creatorID: Int
  var desc: String
  var cat: Int
  var accessible: Bool
  var members: Int
  var posts: Int
  var topics: Int
  var createdAt: Int
  var role: Int
  var joinedAt: Int

  init(_ group: BangumiSchemaV2.GroupV2) {
    groupId = group.groupId
    name = group.name
    nsfw = group.nsfw
    title = group.title
    icon = group.icon
    creatorID = group.creatorID
    desc = group.desc
    cat = group.cat
    accessible = group.accessible
    members = group.members
    posts = group.posts
    topics = group.topics
    createdAt = group.createdAt
    role = group.role
    joinedAt = group.joinedAt
  }
}

struct UserSnapshot: Codable {
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

  init(_ user: BangumiSchemaV2.UserV1) {
    userId = user.userId
    username = user.username
    nickname = user.nickname
    avatar = user.avatar
    group = user.group
    joinedAt = user.joinedAt
    sign = user.sign
    site = user.site
    location = user.location
    bio = user.bio
  }
}

enum BangumiMigrationSnapshotStore {
  private static var directoryURL: URL {
    let baseURL =
      FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
      ?? FileManager.default.temporaryDirectory
    return baseURL.appendingPathComponent("BangumiMigrationV2ToV3", isDirectory: true)
  }

  static func prepare() throws {
    clear()
    try FileManager.default.createDirectory(
      at: directoryURL,
      withIntermediateDirectories: true
    )
  }

  static func writeChunk<Value: Encodable>(
    _ values: [Value],
    prefix: String,
    index: Int
  ) throws {
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.sortedKeys]
    try encoder.encode(values).write(
      to: chunkURL(prefix: prefix, index: index),
      options: .atomic
    )
  }

  static func readChunk<Value: Decodable>(_ type: Value.Type, at url: URL) throws -> [Value] {
    try JSONDecoder().decode([Value].self, from: Data(contentsOf: url))
  }

  static func chunkURLs(prefix: String) -> [URL] {
    guard
      let urls = try? FileManager.default.contentsOfDirectory(
        at: directoryURL,
        includingPropertiesForKeys: nil
      )
    else {
      return []
    }
    return
      urls
      .filter { $0.lastPathComponent.hasPrefix("\(prefix)-") }
      .sorted { $0.lastPathComponent < $1.lastPathComponent }
  }

  private static func chunkURL(prefix: String, index: Int) -> URL {
    directoryURL.appendingPathComponent(
      "\(prefix)-\(String(format: "%05d", index)).json"
    )
  }

  static func clear() {
    try? FileManager.default.removeItem(at: directoryURL)
  }
}
