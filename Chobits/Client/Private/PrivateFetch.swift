//
//  PrivateFetch.swift
//  Chobits
//
//  Created by Chuan Chuan on 2024/10/4.
//

import Foundation
import OSLog

// MARK: - User
extension Chii {
  func listNotice(limit: Int? = nil, unread: Bool? = nil) async throws -> PagedData<NoticeDTO> {
    Logger.api.info("start get notify")
    let url = BangumiAPI.priv.build("p1/notify")
    var queryItems: [URLQueryItem] = []
    if let limit = limit {
      queryItems.append(URLQueryItem(name: "limit", value: String(limit)))
    }
    if let unread = unread {
      queryItems.append(URLQueryItem(name: "unread", value: String(unread)))
    }
    let pageURL = url.appending(queryItems: queryItems)
    let data = try await self.request(url: pageURL, method: "GET", auth: .required)
    let resp: PagedData<NoticeDTO> = try self.decodeResponse(data)
    Logger.api.info("finish get notify")
    return resp
  }
}

// MARK: - Character
extension Chii {
  func getCharacter(_ characterID: Int) async throws -> CharacterDTO {
    Logger.api.info("start get character: \(characterID)")
    let url = BangumiAPI.priv.build("p1/characters/\(characterID)")
    let data = try await self.request(url: url, method: "GET")
    let character: CharacterDTO = try self.decodeResponse(data)
    Logger.api.info("finish get character: \(characterID)")
    return character
  }

  func getCharacterCasts(
    _ characterID: Int, type: Int? = nil, subjectType: SubjectType? = nil, limit: Int = 20,
    offset: Int = 0
  ) async throws -> PagedData<CharacterCastDTO> {
    Logger.api.info("start get character casts")
    let url = BangumiAPI.priv.build("p1/characters/\(characterID)/casts")
    var queryItems: [URLQueryItem] = [
      URLQueryItem(name: "limit", value: String(limit)),
      URLQueryItem(name: "offset", value: String(offset)),
    ]
    if let type = type {
      queryItems.append(URLQueryItem(name: "type", value: String(type)))
    }
    if let subjectType = subjectType {
      queryItems.append(URLQueryItem(name: "subjectType", value: String(subjectType.rawValue)))
    }
    let pageURL = url.appending(queryItems: queryItems)
    let data = try await self.request(url: pageURL, method: "GET")
    let resp: PagedData<CharacterCastDTO> = try self.decodeResponse(data)
    Logger.api.info("finish get character casts")
    return resp
  }

  func getCharacterCollects(_ characterID: Int, limit: Int = 20, offset: Int = 0) async throws
    -> PagedData<PersonCollectDTO>
  {
    Logger.api.info("start get character collects")
    let url = BangumiAPI.priv.build("p1/characters/\(characterID)/collects")
    let queryItems: [URLQueryItem] = [
      URLQueryItem(name: "limit", value: String(limit)),
      URLQueryItem(name: "offset", value: String(offset)),
    ]
    let pageURL = url.appending(queryItems: queryItems)
    let data = try await self.request(url: pageURL, method: "GET")
    let resp: PagedData<PersonCollectDTO> = try self.decodeResponse(data)
    Logger.api.info("finish get character collects")
    return resp
  }

  func getUserCharacterCollections(username: String, limit: Int = 20, offset: Int = 0) async throws
    -> PagedData<UserCharacterCollectionDTO>
  {
    Logger.api.info("start get user character collections")
    let url = BangumiAPI.priv.build("p1/users/\(username)/collections/characters")
    let queryItems: [URLQueryItem] = [
      URLQueryItem(name: "limit", value: String(limit)),
      URLQueryItem(name: "offset", value: String(offset)),
    ]
    let pageURL = url.appending(queryItems: queryItems)
    let data = try await self.request(url: pageURL, method: "GET")
    let resp: PagedData<UserCharacterCollectionDTO> = try self.decodeResponse(data)
    Logger.api.info("finish get user character collections")
    return resp
  }

  func getUserCharacterCollection(username: String, characterID: Int) async throws
    -> UserCharacterCollectionDTO
  {
    Logger.api.info("start get user character collection: \(characterID)")
    let url = BangumiAPI.priv.build("p1/users/\(username)/collections/characters/\(characterID)")
    let data = try await self.request(url: url, method: "GET")
    let collection: UserCharacterCollectionDTO = try self.decodeResponse(data)
    Logger.api.info("finish get user character collection: \(characterID)")
    return collection
  }
}

// MARK: - Person
extension Chii {
  func getPerson(_ personID: Int) async throws -> PersonDTO {
    Logger.api.info("start get person: \(personID)")
    let url = BangumiAPI.priv.build("p1/persons/\(personID)")
    let data = try await self.request(url: url, method: "GET")
    let person: PersonDTO = try self.decodeResponse(data)
    Logger.api.info("finish get person: \(personID)")
    return person
  }

  func getPersonWorks(
    _ personID: Int, position: Int? = nil, subjectType: SubjectType? = nil, limit: Int = 20,
    offset: Int = 0
  ) async throws -> PagedData<PersonWorkDTO> {
    Logger.api.info("start get person works")
    let url = BangumiAPI.priv.build("p1/persons/\(personID)/works")
    var queryItems: [URLQueryItem] = [
      URLQueryItem(name: "limit", value: String(limit)),
      URLQueryItem(name: "offset", value: String(offset)),
    ]
    if let position = position {
      queryItems.append(URLQueryItem(name: "position", value: String(position)))
    }
    if let subjectType = subjectType {
      queryItems.append(URLQueryItem(name: "subjectType", value: String(subjectType.rawValue)))
    }
    let pageURL = url.appending(queryItems: queryItems)
    let data = try await self.request(url: pageURL, method: "GET")
    let resp: PagedData<PersonWorkDTO> = try self.decodeResponse(data)
    Logger.api.info("finish get person works")
    return resp
  }

  func getPersonCasts(
    _ personID: Int, type: Int? = nil, subjectType: SubjectType? = nil, limit: Int = 20,
    offset: Int = 0
  ) async throws -> PagedData<PersonCharacterDTO> {
    Logger.api.info("start get person casts")
    let url = BangumiAPI.priv.build("p1/persons/\(personID)/casts")
    var queryItems: [URLQueryItem] = [
      URLQueryItem(name: "limit", value: String(limit)),
      URLQueryItem(name: "offset", value: String(offset)),
    ]
    if let type = type {
      queryItems.append(URLQueryItem(name: "type", value: String(type)))
    }
    if let subjectType = subjectType {
      queryItems.append(URLQueryItem(name: "subjectType", value: String(subjectType.rawValue)))
    }
    let pageURL = url.appending(queryItems: queryItems)
    let data = try await self.request(url: pageURL, method: "GET")
    let resp: PagedData<PersonCharacterDTO> = try self.decodeResponse(data)
    Logger.api.info("finish get person casts")
    return resp
  }

  func getPersonCollects(_ personID: Int, limit: Int = 20, offset: Int = 0) async throws
    -> PagedData<PersonCollectDTO>
  {
    Logger.api.info("start get person collects")
    let url = BangumiAPI.priv.build("p1/persons/\(personID)/collects")
    let queryItems: [URLQueryItem] = [
      URLQueryItem(name: "limit", value: String(limit)),
      URLQueryItem(name: "offset", value: String(offset)),
    ]
    let pageURL = url.appending(queryItems: queryItems)
    let data = try await self.request(url: pageURL, method: "GET")
    let resp: PagedData<PersonCollectDTO> = try self.decodeResponse(data)
    Logger.api.info("finish get person collects")
    return resp
  }

  func getUserPersonCollections(username: String, limit: Int = 20, offset: Int = 0) async throws
    -> PagedData<UserPersonCollectionDTO>
  {
    Logger.api.info("start get user person collections")
    let url = BangumiAPI.priv.build("p1/users/\(username)/collections/persons")
    let queryItems: [URLQueryItem] = [
      URLQueryItem(name: "limit", value: String(limit)),
      URLQueryItem(name: "offset", value: String(offset)),
    ]
    let pageURL = url.appending(queryItems: queryItems)
    let data = try await self.request(url: pageURL, method: "GET")
    let resp: PagedData<UserPersonCollectionDTO> = try self.decodeResponse(data)
    Logger.api.info("finish get user person collections")
    return resp
  }

  func getUserPersonCollection(username: String, personID: Int) async throws
    -> UserPersonCollectionDTO
  {
    Logger.api.info("start get user person collection: \(personID)")
    let url = BangumiAPI.priv.build("p1/users/\(username)/collections/persons/\(personID)")
    let data = try await self.request(url: url, method: "GET")
    let collection: UserPersonCollectionDTO = try self.decodeResponse(data)
    Logger.api.info("finish get user person collection: \(personID)")
    return collection
  }
}

// MARK: - Subject
extension Chii {
  func getSubject(_ subjectId: Int) async throws -> SubjectDTO {
    if self.mock {
      return loadFixture(fixture: "subject_anime.json", target: SubjectDTO.self)
    }
    Logger.api.info("start get subject: \(subjectId)")
    let url = BangumiAPI.priv.build("p1/subjects/\(subjectId)")
    let data = try await self.request(url: url, method: "GET")
    let subject: SubjectDTO = try self.decodeResponse(data)
    Logger.api.info("finish get subject: \(subjectId)")
    return subject
  }

  func getSubjectEpisodes(
    _ subjectId: Int, type: EpisodeType? = nil, limit: Int = 100, offset: Int = 0
  ) async throws -> PagedData<EpisodeDTO> {
    if self.mock {
      return loadFixture(
        fixture: "subject_episodes.json", target: PagedData<EpisodeDTO>.self)
    }
    Logger.api.info("start get subject episodes")
    let url = BangumiAPI.priv.build("p1/subjects/\(subjectId)/episodes")
    var queryItems: [URLQueryItem] = [
      URLQueryItem(name: "limit", value: String(limit)),
      URLQueryItem(name: "offset", value: String(offset)),
    ]
    if let type = type {
      queryItems.append(URLQueryItem(name: "type", value: String(type.rawValue)))
    }
    let pageURL = url.appending(queryItems: queryItems)
    let data = try await self.request(url: pageURL, method: "GET")
    let resp: PagedData<EpisodeDTO> = try self.decodeResponse(data)
    Logger.api.info("finish get subject episodes")
    return resp
  }

  func getSubjectRelations(
    _ subjectId: Int, type: Int? = nil, offprint: Bool = false, limit: Int = 20, offset: Int = 0
  )
    async throws -> PagedData<SubjectRelationDTO>
  {
    Logger.api.info("start get subject relations")
    let url = BangumiAPI.priv.build("p1/subjects/\(subjectId)/relations")
    var queryItems: [URLQueryItem] = [
      URLQueryItem(name: "limit", value: String(limit)),
      URLQueryItem(name: "offset", value: String(offset)),
    ]
    if let type = type {
      queryItems.append(URLQueryItem(name: "type", value: String(type)))
      queryItems.append(URLQueryItem(name: "offprint", value: String(offprint)))
    }
    let pageURL = url.appending(queryItems: queryItems)
    let data = try await self.request(url: pageURL, method: "GET")
    let resp: PagedData<SubjectRelationDTO> = try self.decodeResponse(data)
    Logger.api.info("finish get subject relations")
    return resp
  }

  func getSubjectCharacters(
    _ subjectId: Int, type: CastType = .unknown,
    limit: Int = 20, offset: Int = 0
  )
    async throws -> PagedData<SubjectCharacterDTO>
  {
    Logger.api.info("start get subject characters")
    let url = BangumiAPI.priv.build("p1/subjects/\(subjectId)/characters")
    var queryItems: [URLQueryItem] = [
      URLQueryItem(name: "limit", value: String(limit)),
      URLQueryItem(name: "offset", value: String(offset)),
    ]
    if type != .unknown {
      queryItems.append(URLQueryItem(name: "type", value: String(type.rawValue)))
    }
    let pageURL = url.appending(queryItems: queryItems)
    let data = try await self.request(url: pageURL, method: "GET")
    let resp: PagedData<SubjectCharacterDTO> = try self.decodeResponse(data)
    Logger.api.info("finish get subject characters")
    return resp
  }

  func getSubjectStaffs(_ subjectId: Int, position: Int? = nil, limit: Int = 20, offset: Int = 0)
    async throws -> PagedData<SubjectStaffDTO>
  {
    Logger.api.info("start get subject staffs")
    let url = BangumiAPI.priv.build("p1/subjects/\(subjectId)/staffs")
    var queryItems: [URLQueryItem] = [
      URLQueryItem(name: "limit", value: String(limit)),
      URLQueryItem(name: "offset", value: String(offset)),
    ]
    if let position = position {
      queryItems.append(URLQueryItem(name: "position", value: String(position)))
    }
    let pageURL = url.appending(queryItems: queryItems)
    let data = try await self.request(url: pageURL, method: "GET")
    let resp: PagedData<SubjectStaffDTO> = try self.decodeResponse(data)
    Logger.api.info("finish get subject staffs")
    return resp
  }

  func getSubjectTopics(_ subjectId: Int, limit: Int, offset: Int = 0) async throws -> PagedData<
    TopicDTO
  > {
    if self.mock {
      return loadFixture(fixture: "subject_topics.json", target: PagedData<TopicDTO>.self)
    }
    Logger.api.info("start get subject topics")
    let url = BangumiAPI.priv.build("p1/subjects/\(subjectId)/topics")
    let queryItems: [URLQueryItem] = [
      URLQueryItem(name: "limit", value: String(limit)),
      URLQueryItem(name: "offset", value: String(offset)),
    ]
    let pageURL = url.appending(queryItems: queryItems)
    let data = try await self.request(url: pageURL, method: "GET")
    let resp: PagedData<TopicDTO> = try self.decodeResponse(data)
    Logger.api.info("finish get subject topics")
    return resp
  }

  func getSubjectComments(_ subjectId: Int, limit: Int, offset: Int = 0) async throws -> PagedData<
    SubjectCommentDTO
  > {
    if self.mock {
      return loadFixture(
        fixture: "subject_comments.json", target: PagedData<SubjectCommentDTO>.self)
    }
    Logger.api.info("start get subject comments")
    let url = BangumiAPI.priv.build("p1/subjects/\(subjectId)/comments")
    let queryItems: [URLQueryItem] = [
      URLQueryItem(name: "limit", value: String(limit)),
      URLQueryItem(name: "offset", value: String(offset)),
    ]
    let pageURL = url.appending(queryItems: queryItems)
    let data = try await self.request(url: pageURL, method: "GET")
    let resp: PagedData<SubjectCommentDTO> = try self.decodeResponse(data)
    Logger.api.info("finish get subject comments")
    return resp
  }

  func getUserSubjectCollection(_ subjectId: Int) async throws -> UserSubjectCollectionDTO {
    if self.mock {
      return loadFixture(
        fixture: "user_collection_anime.json", target: UserSubjectCollectionDTO.self)
    }
    Logger.api.info("start get subject collection: \(subjectId)")
    let profile = try await self.getProfile()
    let url = BangumiAPI.priv.build(
      "p1/users/\(profile.username)/collections/subjects/\(subjectId)")
    let data = try await self.request(url: url, method: "GET")
    let collection: UserSubjectCollectionDTO = try self.decodeResponse(data)
    Logger.api.info("finish get subject collection: \(subjectId)")
    return collection
  }

  func getUserSubjectCollections(
    type: CollectionType = .unknown,
    subjectType: SubjectType = .unknown,
    since: Int = 0, limit: Int = 100, offset: Int = 0
  )
    async throws
    -> PagedData<UserSubjectCollectionDTO>
  {
    if self.mock {
      return loadFixture(
        fixture: "user_collections.json", target: PagedData<UserSubjectCollectionDTO>.self)
    }
    Logger.api.info("start get subject collections")
    let profile = try await self.getProfile()
    let url = BangumiAPI.priv.build("p1/users/\(profile.username)/collections/subjects")
    var queryItems = [
      URLQueryItem(name: "since", value: String(since)),
      URLQueryItem(name: "limit", value: String(limit)),
      URLQueryItem(name: "offset", value: String(offset)),
    ]
    if type != .unknown {
      queryItems.append(URLQueryItem(name: "type", value: String(type.rawValue)))
    }
    if subjectType != .unknown {
      queryItems.append(URLQueryItem(name: "subjectType", value: String(subjectType.rawValue)))
    }
    let pageURL = url.appending(queryItems: queryItems)
    let data = try await self.request(url: pageURL, method: "GET")
    let response: PagedData<UserSubjectCollectionDTO> = try self.decodeResponse(data)
    Logger.api.info("finish get subject collections")
    return response
  }

  func getEpisodeCollections(
    _ subjectId: Int, type: EpisodeType? = nil, limit: Int = 100, offset: Int = 0
  )
    async throws -> PagedData<EpisodeCollectionDTO>
  {
    if self.mock {
      return loadFixture(
        fixture: "episode_collections.json", target: PagedData<EpisodeCollectionDTO>.self)
    }
    Logger.api.info(
      "start get episode collections: \(subjectId), \(type.debugDescription), \(limit), \(offset)")
    var queries: [URLQueryItem] = [
      URLQueryItem(name: "limit", value: String(limit)),
      URLQueryItem(name: "offset", value: String(offset)),
    ]
    if let type = type {
      queries.append(URLQueryItem(name: "episode_type", value: String(type.rawValue)))
    }
    let url = BangumiAPI.priv.build(
      "p1/users/-/collections/subjects/\(subjectId)/episodes"
    )
    .appending(queryItems: queries)
    let data = try await self.request(url: url, method: "GET", auth: .required)
    let resp: PagedData<EpisodeCollectionDTO> = try self.decodeResponse(data)
    Logger.api.info(
      "finish get episode collections: \(subjectId), \(type.debugDescription), \(limit), \(offset)")
    return resp
  }

}
