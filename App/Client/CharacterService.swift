import Foundation

enum CharacterService {
  static func getCharacter(_ characterId: Int) async throws -> CharacterDTO {
    let url = BangumiAPI.priv.build("p1/characters/\(characterId)")
    let data = try await APIClient.shared.request(url: url, method: "GET")
    let character: CharacterDTO = try await APIClient.shared.decodeResponse(data)
    return character
  }

  static func getCharacterCasts(
    _ characterId: Int, type: CastType = .none, subjectType: SubjectType = .none, limit: Int = 20,
    offset: Int = 0
  ) async throws -> PagedDTO<CharacterCastDTO> {
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

  static func getCharacterPhotos(_ characterId: Int, limit: Int = 24, offset: Int = 0)
    async throws -> PagedDTO<MonoPhotoDTO>
  {
    let url = BangumiAPI.priv.build("p1/characters/\(characterId)/photos")
    let queryItems: [URLQueryItem] = [
      URLQueryItem(name: "limit", value: String(limit)),
      URLQueryItem(name: "offset", value: String(offset)),
    ]
    let pageURL = url.appending(queryItems: queryItems)
    let data = try await APIClient.shared.request(url: pageURL, method: "GET")
    let resp: PagedDTO<MonoPhotoDTO> = try await APIClient.shared.decodeResponse(data)
    return resp
  }

  static func getCharacterPhotoPreview(_ characterId: Int, limit: Int = 6)
    async throws -> PagedDTO<MonoPhotoDTO>
  {
    let url = BangumiAPI.priv.build("p1/characters/\(characterId)/photos/preview")
    let pageURL = url.appending(queryItems: [
      URLQueryItem(name: "limit", value: String(limit))
    ])
    let data = try await APIClient.shared.request(url: pageURL, method: "GET")
    let resp: PagedDTO<MonoPhotoDTO> = try await APIClient.shared.decodeResponse(data)
    return resp
  }

  static func getCharacterPhoto(_ characterId: Int, photoId: Int) async throws -> MonoPhotoDTO {
    let url = BangumiAPI.priv.build("p1/characters/\(characterId)/photos/\(photoId)")
    let data = try await APIClient.shared.request(url: url, method: "GET")
    let resp: MonoPhotoDTO = try await APIClient.shared.decodeResponse(data)
    return resp
  }

  static func getCharacterPhotoComments(_ characterId: Int, photoId: Int) async throws
    -> [CommentDTO]
  {
    let url = BangumiAPI.priv.build("p1/characters/\(characterId)/photos/\(photoId)/comments")
    let data = try await APIClient.shared.request(url: url, method: "GET")
    let resp: [CommentDTO] = try await APIClient.shared.decodeResponse(data)
    return resp
  }

  static func getCharacterComments(_ characterId: Int) async throws -> [CommentDTO] {
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

  static func createCharacterPhotoComment(
    characterId: Int, photoId: Int, content: String, replyTo: Int?, token: String
  )
    async throws
  {
    let url = BangumiAPI.priv.build("p1/characters/\(characterId)/photos/\(photoId)/comments")
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
