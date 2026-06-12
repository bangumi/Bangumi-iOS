import Foundation

enum CharacterService {
  static func getCharacter(_ characterId: Int) async throws -> CharacterDTO {
    if await AppContext.shared.isMock {
      return loadFixture(fixture: "character.json", target: CharacterDTO.self)
    }
    let url = BangumiAPI.priv.build("p1/characters/\(characterId)")
    let data = try await APIClient.shared.request(url: url, method: "GET")
    let character: CharacterDTO = try await APIClient.shared.decodeResponse(data)
    return character
  }

  static func getCharacterCasts(
    _ characterId: Int, type: CastType = .none, subjectType: SubjectType = .none, limit: Int = 20,
    offset: Int = 0
  ) async throws -> PagedDTO<CharacterCastDTO> {
    if await AppContext.shared.isMock {
      return loadFixture(
        fixture: "character_casts.json", target: PagedDTO<CharacterCastDTO>.self)
    }
    let url = BangumiAPI.priv.build("p1/characters/\(characterId)/casts")
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
    let data = try await APIClient.shared.request(url: pageURL, method: "GET")
    let resp: PagedDTO<CharacterCastDTO> = try await APIClient.shared.decodeResponse(data)
    return resp
  }

  static func getCharacterRelations(_ characterId: Int, limit: Int = 20, offset: Int = 0)
    async throws -> PagedDTO<CharacterRelationDTO>
  {
    if await AppContext.shared.isMock {
      return loadFixture(
        fixture: "character_relations.json", target: PagedDTO<CharacterRelationDTO>.self)
    }
    let url = BangumiAPI.priv.build("p1/characters/\(characterId)/relations")
    let queryItems: [URLQueryItem] = [
      URLQueryItem(name: "limit", value: String(limit)),
      URLQueryItem(name: "offset", value: String(offset)),
    ]
    let pageURL = url.appending(queryItems: queryItems)
    let data = try await APIClient.shared.request(url: pageURL, method: "GET")
    let resp: PagedDTO<CharacterRelationDTO> = try await APIClient.shared.decodeResponse(data)
    return resp
  }

  static func getCharacterCollects(_ characterId: Int, limit: Int = 20, offset: Int = 0)
    async throws -> PagedDTO<PersonCollectDTO>
  {
    if await AppContext.shared.isMock {
      return loadFixture(
        fixture: "character_collects.json", target: PagedDTO<PersonCollectDTO>.self)
    }
    let url = BangumiAPI.priv.build("p1/characters/\(characterId)/collects")
    let queryItems: [URLQueryItem] = [
      URLQueryItem(name: "limit", value: String(limit)),
      URLQueryItem(name: "offset", value: String(offset)),
    ]
    let pageURL = url.appending(queryItems: queryItems)
    let data = try await APIClient.shared.request(url: pageURL, method: "GET")
    let resp: PagedDTO<PersonCollectDTO> = try await APIClient.shared.decodeResponse(data)
    return resp
  }

  static func getCharacterIndexes(characterId: Int, limit: Int = 20, offset: Int = 0)
    async throws -> PagedDTO<SlimIndexDTO>
  {
    if await AppContext.shared.isMock {
      return loadFixture(fixture: "character_indexes.json", target: PagedDTO<SlimIndexDTO>.self)
    }
    let url = BangumiAPI.priv.build("p1/characters/\(characterId)/indexes")
    let queryItems: [URLQueryItem] = [
      URLQueryItem(name: "limit", value: String(limit)),
      URLQueryItem(name: "offset", value: String(offset)),
    ]
    let pageURL = url.appending(queryItems: queryItems)
    let data = try await APIClient.shared.request(url: pageURL, method: "GET")
    let resp: PagedDTO<SlimIndexDTO> = try await APIClient.shared.decodeResponse(data)
    return resp
  }

  static func getCharacterComments(_ characterId: Int) async throws -> [CommentDTO] {
    if await AppContext.shared.isMock {
      return loadFixture(fixture: "character_comments.json", target: [CommentDTO].self)
    }
    let url = BangumiAPI.priv.build("p1/characters/\(characterId)/comments")
    let data = try await APIClient.shared.request(url: url, method: "GET")
    let resp: [CommentDTO] = try await APIClient.shared.decodeResponse(data)
    return resp
  }

  static func createCharacterComment(
    characterId: Int, content: String, replyTo: Int?, token: String
  )
    async throws
  {
    let url = BangumiAPI.priv.build("p1/characters/\(characterId)/comments")
    var body: [String: Any] = [
      "content": content,
      "turnstileToken": token,
    ]
    if let replyTo {
      body["replyTo"] = replyTo
    }
    _ = try await APIClient.shared.request(url: url, method: "POST", body: body, auth: .required)
  }

  static func collectCharacter(_ characterId: Int) async throws {
    let url = BangumiAPI.priv.build("p1/collections/characters/\(characterId)")
    let body: [String: Any] = [:]
    _ = try await APIClient.shared.request(url: url, method: "PUT", body: body, auth: .required)
  }

  static func uncollectCharacter(_ characterId: Int) async throws {
    let url = BangumiAPI.priv.build("p1/collections/characters/\(characterId)")
    let body: [String: Any] = [:]
    _ = try await APIClient.shared.request(url: url, method: "DELETE", body: body, auth: .required)
  }
}
