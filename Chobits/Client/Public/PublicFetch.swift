//
//  Fetch.swift
//  Chobits
//
//  Created by Chuan Chuan on 2024/5/4.
//

import Foundation
import OSLog

extension Chii {
  func getProfile() async throws -> User {
    if self.mock {
      return loadFixture(fixture: "profile.json", target: User.self)
    }
    if let profile = self.profile {
      return profile
    }
    Logger.api.info("start get profile")
    let url = BangumiAPI.pub.build("v0/me")
    let data = try await request(url: url, method: "GET")
    let profile: User = try self.decodeResponse(data)
    self.profile = profile
    Logger.api.info("finish get profile")
    return profile
  }

  func getUser(uid: String) async throws -> User {
    if self.mock {
      return loadFixture(fixture: "profile.json", target: User.self)
    }
    Logger.api.info("start get user \(uid)")
    let url = BangumiAPI.pub.build("v0/users/\(uid)")
    let data = try await request(url: url, method: "GET")
    let user: User = try self.decodeResponse(data)
    Logger.api.info("finish get user \(uid)")
    return user
  }

  func getSubjectCollections(collectionType: CollectionType, subjectType: SubjectType, offset: Int)
    async throws
    -> SubjectCollectionResponse
  {
    Logger.api.info("start get subject collections")
    let profile = try await self.getProfile()
    let url =
      if profile.username.isEmpty {
        BangumiAPI.pub.build("v0/users/\(profile.id)/collections")
      } else {
        BangumiAPI.pub.build("v0/users/\(profile.username)/collections")
      }
    var queryItems = [
      // limit should less equal than 100
      URLQueryItem(name: "limit", value: "100"),
      URLQueryItem(name: "offset", value: String(offset)),
    ]
    if collectionType != .unknown {
      queryItems.append(URLQueryItem(name: "type", value: String(collectionType.rawValue)))
    }
    if subjectType != .unknown {
      queryItems.append(URLQueryItem(name: "subject_type", value: String(subjectType.rawValue)))
    }
    let pageURL = url.appending(queryItems: queryItems)
    let data = try await request(url: pageURL, method: "GET")
    let response: SubjectCollectionResponse = try self.decodeResponse(data)
    Logger.api.info("finish get subject collections")
    return response
  }

  func getCalendar() async throws -> [BangumiCalendarDTO] {
    Logger.api.info("start get calendar")
    let url = BangumiAPI.pub.build("calendar")
    let data = try await request(url: url, method: "GET", authorized: false)
    let calendars: [BangumiCalendarDTO] = try self.decodeResponse(data)
    Logger.api.info("finish get calendar")
    return calendars
  }

  func search(keyword: String, type: SubjectType = .unknown, limit: Int = 10, offset: Int = 0)
    async throws -> SubjectSearchResponse
  {
    Logger.api.info("start search: \(keyword), \(type.name), \(limit), \(offset)")
    let queries: [URLQueryItem] = [
      URLQueryItem(name: "limit", value: String(limit)),
      URLQueryItem(name: "offset", value: String(offset)),
    ]
    let url = BangumiAPI.pub.build("v0/search/subjects").appending(
      queryItems: queries)
    var body: [String: Any] = [
      "keyword": keyword,
      "sort": "rank",
    ]
    //    排序规则
    //
    //    match meilisearch 的默认排序，按照匹配程度
    //    heat 收藏人数
    //    rank 排名由高到低
    //    score 评分

    if type != .unknown {
      body["filter"] = [
        "type": [type.rawValue]
      ]
    }
    let data = try await self.request(
      url: url, method: "POST", body: body, authorized: self.isAuthenticated()
    )
    let resp: SubjectSearchResponse = try self.decodeResponse(data)
    Logger.api.info("finish search: \(keyword), \(type.name), \(limit), \(offset)")
    return resp
  }

  func getSubjectCollection(_ sid: UInt) async throws -> UserSubjectCollectionDTO {
    if self.mock {
      return loadFixture(
        fixture: "user_collection_anime.json", target: UserSubjectCollectionDTO.self)
    }
    Logger.api.info("start get subject collection: \(sid)")
    let profile = try await self.getProfile()
    let url =
      if profile.username.isEmpty {
        BangumiAPI.pub.build("v0/users/\(profile.id)/collections/\(sid)")
      } else {
        BangumiAPI.pub.build(
          "v0/users/\(profile.username)/collections/\(sid)")
      }
    let data = try await request(url: url, method: "GET")
    let collection: UserSubjectCollectionDTO = try self.decodeResponse(data)
    Logger.api.info("finish get subject collection: \(sid)")
    return collection
  }

  func getSubject(_ sid: UInt) async throws -> SubjectDTO {
    if self.mock {
      return loadFixture(fixture: "subject_anime.json", target: SubjectDTO.self)
    }
    Logger.api.info("start get subject: \(sid)")
    let url = BangumiAPI.pub.build("v0/subjects/\(sid)")
    let data = try await request(url: url, method: "GET", authorized: self.isAuthenticated())
    let subject: SubjectDTO = try self.decodeResponse(data)
    Logger.api.info("finish get subject: \(sid)")
    return subject
  }

  func getSubjects(
    type: SubjectType, filter: SubjectsBrowseFilterDTO, limit: Int = 10, offset: Int = 0
  ) async throws -> SubjectsResponse {
    if self.mock {
      return loadFixture(fixture: "subjects.json", target: SubjectsResponse.self)
    }
    Logger.api.info(
      "start browsing subjects: \(type.description), \(limit), \(offset), \(filter.description)")
    var queries: [URLQueryItem] = [
      URLQueryItem(name: "type", value: String(type.rawValue)),
      URLQueryItem(name: "limit", value: String(limit)),
      URLQueryItem(name: "offset", value: String(offset)),
    ]
    if let cat = filter.cat {
      queries.append(URLQueryItem(name: "cat", value: String(cat.id)))
    }
    if type == .book, let series = filter.series {
      queries.append(URLQueryItem(name: "series", value: String(series)))
    }
    if type == .game, !filter.platform.isEmpty {
      queries.append(URLQueryItem(name: "platform", value: filter.platform))
    }
    if !filter.sort.isEmpty {
      queries.append(URLQueryItem(name: "sort", value: filter.sort))
    }
    if filter.year > 0 {
      queries.append(URLQueryItem(name: "year", value: String(filter.year)))
      if filter.month > 0 {
        queries.append(URLQueryItem(name: "month", value: String(filter.month)))
      }
    }
    let url = BangumiAPI.pub.build("v0/subjects")
      .appending(queryItems: queries)
    let data = try await request(url: url, method: "GET", authorized: self.isAuthenticated())
    let response: SubjectsResponse = try self.decodeResponse(data)
    Logger.api.info(
      "finish browsing subjects: \(type.description), \(limit), \(offset), \(filter.description)")
    return response
  }

  func getSubjectEpisodes(subjectId: UInt, type: EpisodeType?, limit: Int = 10, offset: Int = 0)
    async throws -> EpisodeResponse
  {
    if self.mock {
      return loadFixture(fixture: "episodes.json", target: EpisodeResponse.self)
    }
    Logger.api.info(
      "start get subject episodes: \(subjectId), \(type.debugDescription), \(limit), \(offset)")
    var queries: [URLQueryItem] = [
      URLQueryItem(name: "subject_id", value: String(subjectId)),
      URLQueryItem(name: "limit", value: String(limit)),
      URLQueryItem(name: "offset", value: String(offset)),
    ]
    if let type = type {
      queries.append(URLQueryItem(name: "type", value: String(type.rawValue)))
    }
    let url = BangumiAPI.pub.build("v0/episodes")
      .appending(queryItems: queries)
    let data = try await request(url: url, method: "GET", authorized: self.isAuthenticated())
    let resp: EpisodeResponse = try self.decodeResponse(data)
    Logger.api.info(
      "finish get subject episodes: \(subjectId), \(type.debugDescription), \(limit), \(offset)")
    return resp
  }

  func getEpisodeCollections(
    subjectId: UInt, type: EpisodeType?, limit: Int = 10, offset: Int = 0
  )
    async throws -> EpisodeCollectionResponse
  {
    if self.mock {
      return loadFixture(
        fixture: "episode_collections.json", target: EpisodeCollectionResponse.self)
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
    let url = BangumiAPI.pub.build(
      "v0/users/-/collections/\(subjectId)/episodes"
    )
    .appending(queryItems: queries)
    let data = try await request(url: url, method: "GET", authorized: self.isAuthenticated())
    let resp: EpisodeCollectionResponse = try self.decodeResponse(data)
    Logger.api.info(
      "finish get episode collections: \(subjectId), \(type.debugDescription), \(limit), \(offset)")
    return resp
  }

  func getSubjectCharacters(_ sid: UInt) async throws -> [SubjectCharacterDTO] {
    if self.mock {
      return loadFixture(fixture: "subject_characters.json", target: [SubjectCharacterDTO].self)
    }
    Logger.api.info("start get subject characters: \(sid)")
    let url = BangumiAPI.pub.build("v0/subjects/\(sid)/characters")
    let data = try await request(url: url, method: "GET", authorized: self.isAuthenticated())
    let characters: [SubjectCharacterDTO] = try self.decodeResponse(data)
    Logger.api.info("finish get subject characters: \(sid)")
    return characters
  }

  func getSubjectPersons(_ sid: UInt) async throws -> [SubjectPersonDTO] {
    if self.mock {
      return loadFixture(fixture: "subject_persons.json", target: [SubjectPersonDTO].self)
    }
    Logger.api.info("start get subject persons: \(sid)")
    let url = BangumiAPI.pub.build("v0/subjects/\(sid)/persons")
    let data = try await request(url: url, method: "GET", authorized: self.isAuthenticated())
    let persons: [SubjectPersonDTO] = try self.decodeResponse(data)
    Logger.api.info("finish get subject persons: \(sid)")
    return persons
  }

  func getSubjectRelations(_ sid: UInt) async throws -> [SubjectRelationDTO] {
    if self.mock {
      return loadFixture(fixture: "subject_relations.json", target: [SubjectRelationDTO].self)
    }
    Logger.api.info("start get subject relations: \(sid)")
    let url = BangumiAPI.pub.build("v0/subjects/\(sid)/subjects")
    let data = try await request(url: url, method: "GET", authorized: self.isAuthenticated())
    let relations: [SubjectRelationDTO] = try self.decodeResponse(data)
    Logger.api.info("finish get subject relations: \(sid)")
    return relations
  }

  func getCharacter(_ cid: UInt) async throws -> CharacterDTO {
    if self.mock {
      return loadFixture(fixture: "character.json", target: CharacterDTO.self)
    }
    Logger.api.info("start get characters: \(cid)")
    let url = BangumiAPI.pub.build("v0/characters/\(cid)")
    let data = try await request(url: url, method: "GET", authorized: self.isAuthenticated())
    let character: CharacterDTO = try self.decodeResponse(data)
    Logger.api.info("finish get characters: \(cid)")
    return character
  }

  func getCharacterSubjects(_ cid: UInt) async throws -> [CharacterSubjectDTO] {
    if self.mock {
      return loadFixture(fixture: "character_subjects.json", target: [CharacterSubjectDTO].self)
    }
    Logger.api.info("start get character subjects: \(cid)")
    let url = BangumiAPI.pub.build("v0/characters/\(cid)/subjects")
    let data = try await request(url: url, method: "GET", authorized: self.isAuthenticated())
    let subjects: [CharacterSubjectDTO] = try self.decodeResponse(data)
    Logger.api.info("finish get character subjects: \(cid)")
    return subjects
  }

  func getCharacterPersons(_ cid: UInt) async throws -> [CharacterPersonDTO] {
    if self.mock {
      return loadFixture(fixture: "character_persons.json", target: [CharacterPersonDTO].self)
    }
    Logger.api.info("start get character persons: \(cid)")
    let url = BangumiAPI.pub.build("v0/characters/\(cid)/persons")
    let data = try await request(url: url, method: "GET", authorized: self.isAuthenticated())
    let persons: [CharacterPersonDTO] = try self.decodeResponse(data)
    Logger.api.info("finish get character persons: \(cid)")
    return persons
  }

  func getPerson(_ pid: UInt) async throws -> PersonDTO {
    if self.mock {
      return loadFixture(fixture: "person.json", target: PersonDTO.self)
    }
    Logger.api.info("start get persons: \(pid)")
    let url = BangumiAPI.pub.build("v0/persons/\(pid)")
    let data = try await request(url: url, method: "GET", authorized: self.isAuthenticated())
    let person: PersonDTO = try self.decodeResponse(data)
    Logger.api.info("finish get persons: \(pid)")
    return person
  }

  func getPersonSubjects(_ pid: UInt) async throws -> [PersonSubjectDTO] {
    if self.mock {
      return loadFixture(fixture: "person_subjects.json", target: [PersonSubjectDTO].self)
    }
    Logger.api.info("start get person subjects: \(pid)")
    let url = BangumiAPI.pub.build("v0/persons/\(pid)/subjects")
    let data = try await request(url: url, method: "GET", authorized: self.isAuthenticated())
    let subjects: [PersonSubjectDTO] = try self.decodeResponse(data)
    Logger.api.info("finish get person subjects: \(pid)")
    return subjects
  }

  func getPersonCharacters(_ pid: UInt) async throws -> [PersonCharacterDTO] {
    if self.mock {
      return loadFixture(fixture: "person_characters.json", target: [PersonCharacterDTO].self)
    }
    Logger.api.info("start get person characters: \(pid)")
    let url = BangumiAPI.pub.build("v0/persons/\(pid)/characters")
    let data = try await request(url: url, method: "GET", authorized: self.isAuthenticated())
    let characters: [PersonCharacterDTO] = try self.decodeResponse(data)
    Logger.api.info("finish get person characters: \(pid)")
    return characters
  }
}
