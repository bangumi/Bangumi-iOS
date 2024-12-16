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
  func listNotice(limit: Int? = nil, unread: Bool? = nil) async throws -> PagedDTO<NoticeDTO> {
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
    let resp: PagedDTO<NoticeDTO> = try self.decodeResponse(data)
    return resp
  }
}

// MARK: - Character
extension Chii {
  func getCharacter(_ characterID: Int) async throws -> CharacterDTO {
    if self.mock {
      return loadFixture(fixture: "character.json", target: CharacterDTO.self)
    }
    let url = BangumiAPI.priv.build("p1/characters/\(characterID)")
    let data = try await self.request(url: url, method: "GET")
    let character: CharacterDTO = try self.decodeResponse(data)
    return character
  }

  func getCharacterCasts(
    _ characterID: Int, type: CastType = .none, subjectType: SubjectType = .none, limit: Int = 20,
    offset: Int = 0
  ) async throws -> PagedDTO<CharacterCastDTO> {
    if self.mock {
      return loadFixture(
        fixture: "character_casts.json", target: PagedDTO<CharacterCastDTO>.self)
    }
    let url = BangumiAPI.priv.build("p1/characters/\(characterID)/casts")
    var queryItems: [URLQueryItem] = [
      URLQueryItem(name: "limit", value: String(limit)),
      URLQueryItem(name: "offset", value: String(offset)),
    ]
    if type != .none {
      queryItems.append(URLQueryItem(name: "type", value: String(type.rawValue)))
    }
    if subjectType != .none {
      queryItems.append(URLQueryItem(name: "subjectType", value: String(subjectType.rawValue)))
    }
    let pageURL = url.appending(queryItems: queryItems)
    let data = try await self.request(url: pageURL, method: "GET")
    let resp: PagedDTO<CharacterCastDTO> = try self.decodeResponse(data)
    return resp
  }

  func getCharacterCollects(_ characterID: Int, limit: Int = 20, offset: Int = 0) async throws
    -> PagedDTO<PersonCollectDTO>
  {
    if self.mock {
      return loadFixture(
        fixture: "character_collects.json", target: PagedDTO<PersonCollectDTO>.self)
    }
    let url = BangumiAPI.priv.build("p1/characters/\(characterID)/collects")
    let queryItems: [URLQueryItem] = [
      URLQueryItem(name: "limit", value: String(limit)),
      URLQueryItem(name: "offset", value: String(offset)),
    ]
    let pageURL = url.appending(queryItems: queryItems)
    let data = try await self.request(url: pageURL, method: "GET")
    let resp: PagedDTO<PersonCollectDTO> = try self.decodeResponse(data)
    return resp
  }

  func getUserCharacterCollections(username: String, limit: Int = 20, offset: Int = 0) async throws
    -> PagedDTO<UserCharacterCollectionDTO>
  {
    if self.mock {
      return loadFixture(
        fixture: "user_character_collections.json",
        target: PagedDTO<UserCharacterCollectionDTO>.self)
    }
    let url = BangumiAPI.priv.build("p1/users/\(username)/collections/characters")
    let queryItems: [URLQueryItem] = [
      URLQueryItem(name: "limit", value: String(limit)),
      URLQueryItem(name: "offset", value: String(offset)),
    ]
    let pageURL = url.appending(queryItems: queryItems)
    let data = try await self.request(url: pageURL, method: "GET")
    let resp: PagedDTO<UserCharacterCollectionDTO> = try self.decodeResponse(data)
    return resp
  }

  func getUserCharacterCollection(username: String, characterID: Int) async throws
    -> UserCharacterCollectionDTO
  {
    if self.mock {
      return loadFixture(
        fixture: "user_character_collection.json", target: UserCharacterCollectionDTO.self)
    }
    let url = BangumiAPI.priv.build("p1/users/\(username)/collections/characters/\(characterID)")
    let data = try await self.request(url: url, method: "GET")
    let collection: UserCharacterCollectionDTO = try self.decodeResponse(data)
    return collection
  }
}

// MARK: - Person
extension Chii {
  func getPerson(_ personID: Int) async throws -> PersonDTO {
    if self.mock {
      return loadFixture(fixture: "person.json", target: PersonDTO.self)
    }
    let url = BangumiAPI.priv.build("p1/persons/\(personID)")
    let data = try await self.request(url: url, method: "GET")
    let person: PersonDTO = try self.decodeResponse(data)
    return person
  }

  func getPersonWorks(
    _ personID: Int, position: Int? = nil, subjectType: SubjectType = .none, limit: Int = 20,
    offset: Int = 0
  ) async throws -> PagedDTO<PersonWorkDTO> {
    if self.mock {
      return loadFixture(fixture: "person_works.json", target: PagedDTO<PersonWorkDTO>.self)
    }
    let url = BangumiAPI.priv.build("p1/persons/\(personID)/works")
    var queryItems: [URLQueryItem] = [
      URLQueryItem(name: "limit", value: String(limit)),
      URLQueryItem(name: "offset", value: String(offset)),
    ]
    if let position = position {
      queryItems.append(URLQueryItem(name: "position", value: String(position)))
    }
    if subjectType != .none {
      queryItems.append(URLQueryItem(name: "subjectType", value: String(subjectType.rawValue)))
    }
    let pageURL = url.appending(queryItems: queryItems)
    let data = try await self.request(url: pageURL, method: "GET")
    let resp: PagedDTO<PersonWorkDTO> = try self.decodeResponse(data)
    return resp
  }

  func getPersonCasts(
    _ personID: Int, type: Int? = nil, subjectType: SubjectType? = nil, limit: Int = 20,
    offset: Int = 0
  ) async throws -> PagedDTO<PersonCastDTO> {
    if self.mock {
      return loadFixture(fixture: "person_casts.json", target: PagedDTO<PersonCastDTO>.self)
    }
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
    let resp: PagedDTO<PersonCastDTO> = try self.decodeResponse(data)
    return resp
  }

  func getPersonCollects(_ personID: Int, limit: Int = 20, offset: Int = 0) async throws
    -> PagedDTO<PersonCollectDTO>
  {
    if self.mock {
      return loadFixture(
        fixture: "person_collects.json", target: PagedDTO<PersonCollectDTO>.self)
    }
    let url = BangumiAPI.priv.build("p1/persons/\(personID)/collects")
    let queryItems: [URLQueryItem] = [
      URLQueryItem(name: "limit", value: String(limit)),
      URLQueryItem(name: "offset", value: String(offset)),
    ]
    let pageURL = url.appending(queryItems: queryItems)
    let data = try await self.request(url: pageURL, method: "GET")
    let resp: PagedDTO<PersonCollectDTO> = try self.decodeResponse(data)
    return resp
  }

  func getUserPersonCollections(username: String, limit: Int = 20, offset: Int = 0) async throws
    -> PagedDTO<UserPersonCollectionDTO>
  {
    if self.mock {
      return loadFixture(
        fixture: "user_person_collections.json", target: PagedDTO<UserPersonCollectionDTO>.self)
    }
    if self.mock {
      return loadFixture(
        fixture: "user_person_collections.json", target: PagedDTO<UserPersonCollectionDTO>.self)
    }
    let url = BangumiAPI.priv.build("p1/users/\(username)/collections/persons")
    let queryItems: [URLQueryItem] = [
      URLQueryItem(name: "limit", value: String(limit)),
      URLQueryItem(name: "offset", value: String(offset)),
    ]
    let pageURL = url.appending(queryItems: queryItems)
    let data = try await self.request(url: pageURL, method: "GET")
    let resp: PagedDTO<UserPersonCollectionDTO> = try self.decodeResponse(data)
    return resp
  }

  func getUserPersonCollection(username: String, personID: Int) async throws
    -> UserPersonCollectionDTO
  {
    if self.mock {
      return loadFixture(
        fixture: "user_person_collection.json", target: UserPersonCollectionDTO.self)
    }
    let url = BangumiAPI.priv.build("p1/users/\(username)/collections/persons/\(personID)")
    let data = try await self.request(url: url, method: "GET")
    let collection: UserPersonCollectionDTO = try self.decodeResponse(data)
    return collection
  }
}

// MARK: - Subject
extension Chii {
  func getSubject(_ subjectId: Int) async throws -> SubjectDTO {
    if self.mock {
      return loadFixture(fixture: "subject_anime.json", target: SubjectDTO.self)
    }
    let url = BangumiAPI.priv.build("p1/subjects/\(subjectId)")
    let data = try await self.request(url: url, method: "GET")
    let subject: SubjectDTO = try self.decodeResponse(data)
    return subject
  }

  func getSubjectEpisodes(
    _ subjectId: Int, type: EpisodeType? = nil, limit: Int = 100, offset: Int = 0
  ) async throws -> PagedDTO<EpisodeDTO> {
    if self.mock {
      return loadFixture(
        fixture: "subject_episodes.json", target: PagedDTO<EpisodeDTO>.self)
    }
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
    let resp: PagedDTO<EpisodeDTO> = try self.decodeResponse(data)
    return resp
  }

  func getSubjectRelations(
    _ subjectId: Int, type: SubjectType = .none, offprint: Bool? = nil, limit: Int = 20,
    offset: Int = 0
  )
    async throws -> PagedDTO<SubjectRelationDTO>
  {
    if self.mock {
      if offprint == true {
        return loadFixture(
          fixture: "subject_offprints.json", target: PagedDTO<SubjectRelationDTO>.self)
      } else {
        return loadFixture(
          fixture: "subject_relations.json", target: PagedDTO<SubjectRelationDTO>.self)
      }
    }
    let url = BangumiAPI.priv.build("p1/subjects/\(subjectId)/relations")
    var queryItems: [URLQueryItem] = [
      URLQueryItem(name: "limit", value: String(limit)),
      URLQueryItem(name: "offset", value: String(offset)),
    ]
    if let offprint = offprint {
      queryItems.append(URLQueryItem(name: "offprint", value: String(offprint)))
    }
    if type != .none {
      queryItems.append(URLQueryItem(name: "type", value: String(type.rawValue)))
    }
    let pageURL = url.appending(queryItems: queryItems)
    let data = try await self.request(url: pageURL, method: "GET")
    let resp: PagedDTO<SubjectRelationDTO> = try self.decodeResponse(data)
    return resp
  }

  func getSubjectCharacters(
    _ subjectId: Int, type: CastType = .none,
    limit: Int = 20, offset: Int = 0
  )
    async throws -> PagedDTO<SubjectCharacterDTO>
  {
    if self.mock {
      return loadFixture(
        fixture: "subject_characters.json", target: PagedDTO<SubjectCharacterDTO>.self)
    }
    let url = BangumiAPI.priv.build("p1/subjects/\(subjectId)/characters")
    var queryItems: [URLQueryItem] = [
      URLQueryItem(name: "limit", value: String(limit)),
      URLQueryItem(name: "offset", value: String(offset)),
    ]
    if type != .none {
      queryItems.append(URLQueryItem(name: "type", value: String(type.rawValue)))
    }
    let pageURL = url.appending(queryItems: queryItems)
    let data = try await self.request(url: pageURL, method: "GET")
    let resp: PagedDTO<SubjectCharacterDTO> = try self.decodeResponse(data)
    return resp
  }

  func getSubjectStaffs(_ subjectId: Int, position: Int? = nil, limit: Int = 20, offset: Int = 0)
    async throws -> PagedDTO<SubjectStaffDTO>
  {
    if self.mock {
      return loadFixture(
        fixture: "subject_staffs.json", target: PagedDTO<SubjectStaffDTO>.self)
    }
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
    let resp: PagedDTO<SubjectStaffDTO> = try self.decodeResponse(data)
    return resp
  }

  func getSubjectTopics(_ subjectId: Int, limit: Int, offset: Int = 0) async throws -> PagedDTO<
    TopicDTO
  > {
    if self.mock {
      return loadFixture(fixture: "subject_topics.json", target: PagedDTO<TopicDTO>.self)
    }
    let url = BangumiAPI.priv.build("p1/subjects/\(subjectId)/topics")
    let queryItems: [URLQueryItem] = [
      URLQueryItem(name: "limit", value: String(limit)),
      URLQueryItem(name: "offset", value: String(offset)),
    ]
    let pageURL = url.appending(queryItems: queryItems)
    let data = try await self.request(url: pageURL, method: "GET")
    let resp: PagedDTO<TopicDTO> = try self.decodeResponse(data)
    return resp
  }

  func getSubjectComments(_ subjectId: Int, limit: Int, offset: Int = 0) async throws -> PagedDTO<
    SubjectCommentDTO
  > {
    if self.mock {
      return loadFixture(
        fixture: "subject_comments.json", target: PagedDTO<SubjectCommentDTO>.self)
    }
    let url = BangumiAPI.priv.build("p1/subjects/\(subjectId)/comments")
    let queryItems: [URLQueryItem] = [
      URLQueryItem(name: "limit", value: String(limit)),
      URLQueryItem(name: "offset", value: String(offset)),
    ]
    let pageURL = url.appending(queryItems: queryItems)
    let data = try await self.request(url: pageURL, method: "GET")
    let resp: PagedDTO<SubjectCommentDTO> = try self.decodeResponse(data)
    return resp
  }

  func getUserSubjectCollection(_ subjectId: Int) async throws -> UserSubjectCollectionDTO {
    if self.mock {
      return loadFixture(
        fixture: "user_subject_collection_anime.json", target: UserSubjectCollectionDTO.self)
    }
    let profile = try await self.getProfile()
    let url = BangumiAPI.priv.build(
      "p1/users/\(profile.username)/collections/subjects/\(subjectId)")
    let data = try await self.request(url: url, method: "GET")
    let collection: UserSubjectCollectionDTO = try self.decodeResponse(data)
    return collection
  }

  func getUserSubjectCollections(
    type: CollectionType = .none,
    subjectType: SubjectType = .none,
    since: Int = 0, limit: Int = 100, offset: Int = 0
  )
    async throws
    -> PagedDTO<UserSubjectCollectionDTO>
  {
    if self.mock {
      return loadFixture(
        fixture: "user_subject_collections.json", target: PagedDTO<UserSubjectCollectionDTO>.self)
    }
    let profile = try await self.getProfile()
    let url = BangumiAPI.priv.build("p1/users/\(profile.username)/collections/subjects")
    var queryItems = [
      URLQueryItem(name: "since", value: String(since)),
      URLQueryItem(name: "limit", value: String(limit)),
      URLQueryItem(name: "offset", value: String(offset)),
    ]
    if type != .none {
      queryItems.append(URLQueryItem(name: "type", value: String(type.rawValue)))
    }
    if subjectType != .none {
      queryItems.append(URLQueryItem(name: "subjectType", value: String(subjectType.rawValue)))
    }
    let pageURL = url.appending(queryItems: queryItems)
    let data = try await self.request(url: pageURL, method: "GET")
    let response: PagedDTO<UserSubjectCollectionDTO> = try self.decodeResponse(data)
    return response
  }

  func getEpisodeCollections(
    _ subjectId: Int, type: EpisodeType? = nil, limit: Int = 100, offset: Int = 0
  )
    async throws -> PagedDTO<EpisodeCollectionDTO>
  {
    if self.mock {
      return loadFixture(
        fixture: "episode_collections.json", target: PagedDTO<EpisodeCollectionDTO>.self)
    }
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
    let resp: PagedDTO<EpisodeCollectionDTO> = try self.decodeResponse(data)
    return resp
  }

  func getSubjectRecs(_ subjectId: Int, limit: Int = 10, offset: Int = 0) async throws -> PagedDTO<
    SubjectRecDTO
  > {
    if self.mock {
      return loadFixture(fixture: "subject_recs.json", target: PagedDTO<SubjectRecDTO>.self)
    }
    let url = BangumiAPI.priv.build("p1/subjects/\(subjectId)/recs")
    let queryItems: [URLQueryItem] = [
      URLQueryItem(name: "limit", value: String(limit)),
      URLQueryItem(name: "offset", value: String(offset)),
    ]
    let pageURL = url.appending(queryItems: queryItems)
    let data = try await self.request(url: pageURL, method: "GET")
    let resp: PagedDTO<SubjectRecDTO> = try self.decodeResponse(data)
    return resp
  }

  func getSubjectReviews(_ subjectId: Int, limit: Int = 5, offset: Int = 0) async throws
    -> PagedDTO<SubjectReviewDTO>
  {
    if self.mock {
      return loadFixture(fixture: "subject_reviews.json", target: PagedDTO<SubjectReviewDTO>.self)
    }
    let url = BangumiAPI.priv.build("p1/subjects/\(subjectId)/reviews")
    let queryItems: [URLQueryItem] = [
      URLQueryItem(name: "limit", value: String(limit)),
      URLQueryItem(name: "offset", value: String(offset)),
    ]
    let pageURL = url.appending(queryItems: queryItems)
    let data = try await self.request(url: pageURL, method: "GET")
    let resp: PagedDTO<SubjectReviewDTO> = try self.decodeResponse(data)
    return resp
  }
}
