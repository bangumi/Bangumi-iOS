import Foundation

enum WikiService {
  private static func body<T: Encodable>(_ value: T) throws -> Any {
    let data = try JSONEncoder().encode(value)
    return try JSONSerialization.jsonObject(with: data)
  }

  private static func bodyWithoutEmptyInfobox(_ value: SimpleWikiExpectedDTO) throws -> [String: Any] {
    var payload = try body(value) as? [String: Any] ?? [:]
    if value.infobox?.isEmpty ?? true {
      payload.removeValue(forKey: "infobox")
    }
    return payload
  }

  private static func pageURL(_ path: String, limit: Int, offset: Int) -> URL {
    BangumiURL.next(path: path).appending(queryItems: [
      URLQueryItem(name: "limit", value: String(limit)),
      URLQueryItem(name: "offset", value: String(offset)),
    ])
  }

  private static func recentURL(_ path: String, since: Int?) -> URL {
    var queryItems: [URLQueryItem] = []
    if let since {
      queryItems.append(URLQueryItem(name: "since", value: String(since)))
    }
    return BangumiURL.next(path: path).appending(queryItems: queryItems)
  }

  static func getSubjectWikiInfo(_ subjectId: Int) async throws -> SubjectWikiInfoDTO {
    let url = BangumiURL.next(path: "p1/wiki/subjects/\(subjectId)")
    let data = try await APIClient.shared.request(url: url, method: "GET")
    return try await APIClient.shared.decodeResponse(data)
  }

  static func createSubject(_ subject: SubjectWikiEditDTO, type: SubjectType) async throws -> Int {
    let url = BangumiURL.next(path: "p1/wiki/subjects")
    var payload = try body(subject) as? [String: Any] ?? [:]
    payload["type"] = type.rawValue
    let data = try await APIClient.shared.request(
      url: url,
      method: "POST",
      body: payload,
      auth: .required
    )
    let response: SubjectCreateResponseDTO = try await APIClient.shared.decodeResponse(data)
    return response.subjectID
  }

  static func updateSubjectWikiInfo(
    subjectId: Int,
    subject: SubjectWikiEditDTO,
    expectedRevision: SubjectWikiExpectedDTO?,
    commitMessage: String
  ) async throws {
    let url = BangumiURL.next(path: "p1/wiki/subjects/\(subjectId)")
    var payload: [String: Any] = [
      "commitMessage": commitMessage,
      "subject": try body(subject),
    ]
    if let expectedRevision {
      payload["expectedRevision"] = try body(expectedRevision)
    }
    _ = try await APIClient.shared.request(url: url, method: "PUT", body: payload, auth: .required)
  }

  static func patchSubjectWikiInfo(
    subjectId: Int,
    subject: SubjectWikiEditDTO,
    expectedRevision: SubjectWikiExpectedDTO?,
    commitMessage: String,
    originalInfo: SubjectWikiInfoDTO? = nil
  ) async throws {
    let url = BangumiURL.next(path: "p1/wiki/subjects/\(subjectId)")
    var subjectPayload = try body(subject) as? [String: Any] ?? [:]
    if let originalInfo {
      if subject.series == originalInfo.series {
        subjectPayload.removeValue(forKey: "series")
      }
      if subject.nsfw == originalInfo.nsfw {
        subjectPayload.removeValue(forKey: "nsfw")
      }
      if subject.infobox.isEmpty {
        subjectPayload.removeValue(forKey: "infobox")
      }
    }
    var payload: [String: Any] = [
      "commitMessage": commitMessage,
      "subject": subjectPayload,
    ]
    if let expectedRevision {
      payload["expectedRevision"] = try body(expectedRevision)
    }
    _ = try await APIClient.shared.request(url: url, method: "PATCH", body: payload, auth: .required)
  }

  static func lockSubject(subjectId: Int, reason: String) async throws {
    let url = BangumiURL.next(path: "p1/wiki/lock/subjects")
    let payload: [String: Any] = ["subjectID": subjectId, "reason": reason]
    _ = try await APIClient.shared.request(url: url, method: "POST", body: payload, auth: .required)
  }

  static func unlockSubject(subjectId: Int, reason: String) async throws {
    let url = BangumiURL.next(path: "p1/wiki/unlock/subjects")
    let payload: [String: Any] = ["subjectID": subjectId, "reason": reason]
    _ = try await APIClient.shared.request(url: url, method: "POST", body: payload, auth: .required)
  }

  static func getSubjectCovers(_ subjectId: Int) async throws -> SubjectCoverListDTO {
    let url = BangumiURL.next(path: "p1/wiki/subjects/\(subjectId)/covers")
    let data = try await APIClient.shared.request(url: url, method: "GET", auth: .required)
    return try await APIClient.shared.decodeResponse(data)
  }

  static func uploadSubjectCover(subjectId: Int, content: String) async throws {
    let url = BangumiURL.next(path: "p1/wiki/subjects/\(subjectId)/covers")
    let payload: [String: Any] = ["content": content]
    _ = try await APIClient.shared.request(url: url, method: "POST", body: payload, auth: .required)
  }

  static func voteSubjectCover(subjectId: Int, imageId: Int) async throws {
    let url = BangumiURL.next(path: "p1/wiki/subjects/\(subjectId)/covers/\(imageId)/vote")
    _ = try await APIClient.shared.request(url: url, method: "POST", body: [:], auth: .required)
  }

  static func unvoteSubjectCover(subjectId: Int, imageId: Int) async throws {
    let url = BangumiURL.next(path: "p1/wiki/subjects/\(subjectId)/covers/\(imageId)/vote")
    _ = try await APIClient.shared.request(url: url, method: "DELETE", body: [:], auth: .required)
  }

  static func createEpisodes(subjectId: Int, episodes: [EpisodeWikiEditDTO]) async throws -> [Int] {
    let url = BangumiURL.next(path: "p1/wiki/subjects/\(subjectId)/ep")
    let payload: [String: Any] = ["episodes": try body(episodes)]
    let data = try await APIClient.shared.request(
      url: url,
      method: "POST",
      body: payload,
      auth: .required
    )
    let response: EpisodeCreateResponseDTO = try await APIClient.shared.decodeResponse(data)
    return response.episodeIDs
  }

  static func patchEpisodes(
    subjectId: Int,
    episodes: [EpisodeWikiEditDTO],
    expectedRevision: [EpisodeWikiExpectedDTO]?,
    commitMessage: String
  ) async throws {
    let url = BangumiURL.next(path: "p1/wiki/subjects/\(subjectId)/ep")
    var payload: [String: Any] = [
      "commitMessage": commitMessage,
      "episodes": try body(episodes),
    ]
    if let expectedRevision {
      payload["expectedRevision"] = try body(expectedRevision)
    }
    _ = try await APIClient.shared.request(url: url, method: "PATCH", body: payload, auth: .required)
  }

  static func getPersonWikiInfo(_ personId: Int) async throws -> PersonWikiInfoDTO {
    let url = BangumiURL.next(path: "p1/wiki/persons/\(personId)")
    let data = try await APIClient.shared.request(url: url, method: "GET")
    return try await APIClient.shared.decodeResponse(data)
  }

  static func createPerson(
    name: String,
    type: PersonType,
    infobox: String,
    summary: String,
    profession: PersonProfessionDTO,
    imageBase64: String?
  ) async throws -> Int {
    let url = BangumiURL.next(path: "p1/wiki/persons")
    var person: [String: Any] = [
      "name": name,
      "type": type.rawValue,
      "infobox": infobox,
      "summary": summary,
      "profession": profession.bodyValue,
    ]
    if let imageBase64 {
      person["img"] = imageBase64
    }
    let payload: [String: Any] = ["person": person]
    let data = try await APIClient.shared.request(
      url: url,
      method: "POST",
      body: payload,
      auth: .required
    )
    let response: PersonCreateResponseDTO = try await APIClient.shared.decodeResponse(data)
    return response.personID
  }

  static func patchPersonWikiInfo(
    personId: Int,
    person: PersonWikiEditDTO,
    originalProfession: PersonProfessionDTO,
    expectedRevision: SimpleWikiExpectedDTO?,
    commitMessage: String
  ) async throws {
    let url = BangumiURL.next(path: "p1/wiki/persons/\(personId)")
    var personPayload: [String: Any] = [
      "name": person.name,
      "summary": person.summary,
    ]
    if person.profession.bodyValue != originalProfession.bodyValue {
      personPayload["profession"] = person.profession.bodyValue
    }
    if !person.infobox.isEmpty {
      personPayload["infobox"] = person.infobox
    }
    var payload: [String: Any] = [
      "commitMessage": commitMessage,
      "person": personPayload,
    ]
    if let expectedRevision {
      payload["expectedRevision"] = try bodyWithoutEmptyInfobox(expectedRevision)
    }
    _ = try await APIClient.shared.request(url: url, method: "PATCH", body: payload, auth: .required)
  }

  static func uploadPersonPortrait(personId: Int, imageBase64: String) async throws -> String {
    let url = BangumiURL.next(path: "p1/wiki/persons/\(personId)/portraits")
    let payload: [String: Any] = ["img": imageBase64]
    let data = try await APIClient.shared.request(
      url: url,
      method: "POST",
      body: payload,
      auth: .required
    )
    let response: MonoPortraitResponseDTO = try await APIClient.shared.decodeResponse(data)
    return response.img
  }

  static func getCharacterWikiInfo(_ characterId: Int) async throws -> CharacterWikiInfoDTO {
    let url = BangumiURL.next(path: "p1/wiki/characters/\(characterId)")
    let data = try await APIClient.shared.request(url: url, method: "GET")
    return try await APIClient.shared.decodeResponse(data)
  }

  static func createCharacter(
    name: String,
    type: CharacterType,
    infobox: String,
    summary: String,
    imageBase64: String?
  ) async throws -> Int {
    let url = BangumiURL.next(path: "p1/wiki/characters")
    var character: [String: Any] = [
      "name": name,
      "type": type.rawValue,
      "infobox": infobox,
      "summary": summary,
    ]
    if let imageBase64 {
      character["img"] = imageBase64
    }
    let payload: [String: Any] = ["character": character]
    let data = try await APIClient.shared.request(
      url: url,
      method: "POST",
      body: payload,
      auth: .required
    )
    let response: CharacterCreateResponseDTO = try await APIClient.shared.decodeResponse(data)
    return response.characterID
  }

  static func patchCharacterWikiInfo(
    characterId: Int,
    character: CharacterWikiEditDTO,
    expectedRevision: SimpleWikiExpectedDTO?,
    commitMessage: String
  ) async throws {
    let url = BangumiURL.next(path: "p1/wiki/characters/\(characterId)")
    var characterPayload = try body(character) as? [String: Any] ?? [:]
    if character.infobox.isEmpty {
      characterPayload.removeValue(forKey: "infobox")
    }
    var payload: [String: Any] = [
      "commitMessage": commitMessage,
      "character": characterPayload,
    ]
    if let expectedRevision {
      payload["expectedRevision"] = try bodyWithoutEmptyInfobox(expectedRevision)
    }
    _ = try await APIClient.shared.request(url: url, method: "PATCH", body: payload, auth: .required)
  }

  static func uploadCharacterPortrait(characterId: Int, imageBase64: String) async throws -> String {
    let url = BangumiURL.next(path: "p1/wiki/characters/\(characterId)/portraits")
    let payload: [String: Any] = ["img": imageBase64]
    let data = try await APIClient.shared.request(
      url: url,
      method: "POST",
      body: payload,
      auth: .required
    )
    let response: MonoPortraitResponseDTO = try await APIClient.shared.decodeResponse(data)
    return response.img
  }

  static func getEpisodeWikiInfo(_ episodeId: Int) async throws -> EpisodeWikiInfoDTO {
    let url = BangumiURL.next(path: "p1/wiki/ep/\(episodeId)")
    let data = try await APIClient.shared.request(url: url, method: "GET")
    return try await APIClient.shared.decodeResponse(data)
  }

  static func patchEpisodeWikiInfo(
    episodeId: Int,
    episode: EpisodeWikiEditDTO,
    expectedRevision: EpisodeWikiExpectedDTO?,
    commitMessage: String
  ) async throws {
    let url = BangumiURL.next(path: "p1/wiki/ep/\(episodeId)")
    var payload: [String: Any] = [
      "commitMessage": commitMessage,
      "episode": try body(episode),
    ]
    if let expectedRevision {
      payload["expectedRevision"] = try body(expectedRevision)
    }
    _ = try await APIClient.shared.request(url: url, method: "PATCH", body: payload, auth: .required)
  }

  static func getHistory(
    kind: WikiHistoryKind,
    entityId: Int,
    limit: Int = 20,
    offset: Int = 0
  ) async throws -> PagedDTO<WikiRevisionHistoryDTO> {
    let path: String
    switch kind {
    case .subject:
      path = "p1/wiki/subjects/\(entityId)/history-summary"
    case .subjectRelations:
      path = "p1/wiki/subjects/\(entityId)/relations/history-summary"
    case .subjectCharacters:
      path = "p1/wiki/subjects/\(entityId)/characters/history-summary"
    case .subjectPersons:
      path = "p1/wiki/subjects/\(entityId)/persons/history-summary"
    case .person:
      path = "p1/wiki/persons/\(entityId)/history-summary"
    case .personSubjects:
      path = "p1/wiki/persons/\(entityId)/subjects/history-summary"
    case .personCasts:
      path = "p1/wiki/persons/\(entityId)/casts/history-summary"
    case .character:
      path = "p1/wiki/characters/\(entityId)/history-summary"
    case .characterSubjects:
      path = "p1/wiki/characters/\(entityId)/subjects/history-summary"
    case .characterCasts:
      path = "p1/wiki/characters/\(entityId)/casts/history-summary"
    }
    let data = try await APIClient.shared.request(
      url: pageURL(path, limit: limit, offset: offset),
      method: "GET"
    )
    return try await APIClient.shared.decodeResponse(data)
  }

  static func getSubjectRevision(_ revisionId: Int) async throws -> SubjectWikiRevisionDTO {
    let url = BangumiURL.next(path: "p1/wiki/subjects/-/revisions/\(revisionId)")
    let data = try await APIClient.shared.request(url: url, method: "GET")
    return try await APIClient.shared.decodeResponse(data)
  }

  static func getPersonRevision(_ revisionId: Int) async throws -> PersonWikiRevisionDTO {
    let url = BangumiURL.next(path: "p1/wiki/persons/-/revisions/\(revisionId)")
    let data = try await APIClient.shared.request(url: url, method: "GET")
    return try await APIClient.shared.decodeResponse(data)
  }

  static func getCharacterRevision(_ revisionId: Int) async throws -> CharacterWikiRevisionDTO {
    let url = BangumiURL.next(path: "p1/wiki/characters/-/revisions/\(revisionId)")
    let data = try await APIClient.shared.request(url: url, method: "GET")
    return try await APIClient.shared.decodeResponse(data)
  }

  static func getSubjectRelationRevision(_ revisionId: Int) async throws
    -> [SubjectRelationRevisionDTO]
  {
    let url = BangumiURL.next(path: "p1/wiki/subjects/-/relations/revisions/\(revisionId)")
    let data = try await APIClient.shared.request(url: url, method: "GET")
    return try await APIClient.shared.decodeResponse(data)
  }

  static func getSubjectCharacterRevision(_ revisionId: Int) async throws
    -> [SubjectCharacterRevisionDTO]
  {
    let url = BangumiURL.next(path: "p1/wiki/subjects/-/characters/revisions/\(revisionId)")
    let data = try await APIClient.shared.request(url: url, method: "GET")
    return try await APIClient.shared.decodeResponse(data)
  }

  static func getSubjectPersonRevision(_ revisionId: Int) async throws -> [SubjectPersonRevisionDTO]
  {
    let url = BangumiURL.next(path: "p1/wiki/subjects/-/persons/revisions/\(revisionId)")
    let data = try await APIClient.shared.request(url: url, method: "GET")
    return try await APIClient.shared.decodeResponse(data)
  }

  static func getPersonSubjectRevision(_ revisionId: Int) async throws -> [PersonSubjectRevisionDTO]
  {
    let url = BangumiURL.next(path: "p1/wiki/persons/-/subjects/revisions/\(revisionId)")
    let data = try await APIClient.shared.request(url: url, method: "GET")
    return try await APIClient.shared.decodeResponse(data)
  }

  static func getPersonCastRevision(_ revisionId: Int) async throws -> [PersonCastRevisionDTO] {
    let url = BangumiURL.next(path: "p1/wiki/persons/-/casts/revisions/\(revisionId)")
    let data = try await APIClient.shared.request(url: url, method: "GET")
    return try await APIClient.shared.decodeResponse(data)
  }

  static func getCharacterSubjectRevision(_ revisionId: Int) async throws
    -> [CharacterSubjectRevisionDTO]
  {
    let url = BangumiURL.next(path: "p1/wiki/characters/-/subjects/revisions/\(revisionId)")
    let data = try await APIClient.shared.request(url: url, method: "GET")
    return try await APIClient.shared.decodeResponse(data)
  }

  static func getCharacterCastRevision(_ revisionId: Int) async throws
    -> [CharacterCastRevisionDTO]
  {
    let url = BangumiURL.next(path: "p1/wiki/characters/-/casts/revisions/\(revisionId)")
    let data = try await APIClient.shared.request(url: url, method: "GET")
    return try await APIClient.shared.decodeResponse(data)
  }

  static func getRecentSubjects(since: Int? = nil) async throws -> SubjectRecentWikiDTO {
    let data = try await APIClient.shared.request(
      url: recentURL("p1/wiki/recent/subjects", since: since),
      method: "GET"
    )
    return try await APIClient.shared.decodeResponse(data)
  }

  static func getRecentPersons(since: Int? = nil) async throws -> [WikiRecentItemDTO] {
    let data = try await APIClient.shared.request(
      url: recentURL("p1/wiki/recent/persons", since: since),
      method: "GET"
    )
    return try await APIClient.shared.decodeResponse(data)
  }

  static func getRecentCharacters(since: Int? = nil) async throws -> [WikiRecentItemDTO] {
    let data = try await APIClient.shared.request(
      url: recentURL("p1/wiki/recent/characters", since: since),
      method: "GET"
    )
    return try await APIClient.shared.decodeResponse(data)
  }

  static func getRecentEpisodes(since: Int? = nil) async throws -> [WikiRecentItemDTO] {
    let data = try await APIClient.shared.request(
      url: recentURL("p1/wiki/recent/episodes", since: since),
      method: "GET"
    )
    return try await APIClient.shared.decodeResponse(data)
  }

  static func getUserContributedSubjects(
    username: String,
    limit: Int = 20,
    offset: Int = 0
  ) async throws -> PagedDTO<WikiSubjectContributionDTO> {
    let data = try await APIClient.shared.request(
      url: pageURL("p1/wiki/users/\(username)/contributions/subjects", limit: limit, offset: offset),
      method: "GET"
    )
    return try await APIClient.shared.decodeResponse(data)
  }

  static func getUserContributedPersons(
    username: String,
    limit: Int = 20,
    offset: Int = 0
  ) async throws -> PagedDTO<WikiPersonContributionDTO> {
    let data = try await APIClient.shared.request(
      url: pageURL("p1/wiki/users/\(username)/contributions/persons", limit: limit, offset: offset),
      method: "GET"
    )
    return try await APIClient.shared.decodeResponse(data)
  }

  static func getUserContributedCharacters(
    username: String,
    limit: Int = 20,
    offset: Int = 0
  ) async throws -> PagedDTO<WikiCharacterContributionDTO> {
    let data = try await APIClient.shared.request(
      url: pageURL(
        "p1/wiki/users/\(username)/contributions/characters",
        limit: limit,
        offset: offset
      ),
      method: "GET"
    )
    return try await APIClient.shared.decodeResponse(data)
  }
}
