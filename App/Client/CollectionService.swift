import Foundation

enum CollectionService {
  static func getCharacterCollections(limit: Int = 20, offset: Int = 0) async throws
    -> PagedDTO<CharacterDTO>
  {
    let url = BangumiAPI.priv.build("p1/collections/characters")
    let data = try await APIClient.shared.request(
      url: url.appending(queryItems: paginationQueryItems(limit: limit, offset: offset)),
      method: "GET",
      auth: .required)
    let resp: PagedDTO<CharacterDTO> = try await APIClient.shared.decodeResponse(data)
    return resp
  }

  static func getIndexCollections(limit: Int = 20, offset: Int = 0) async throws
    -> PagedDTO<IndexDTO>
  {
    let url = BangumiAPI.priv.build("p1/collections/indexes")
    let data = try await APIClient.shared.request(
      url: url.appending(queryItems: paginationQueryItems(limit: limit, offset: offset)),
      method: "GET",
      auth: .required)
    let resp: PagedDTO<IndexDTO> = try await APIClient.shared.decodeResponse(data)
    return resp
  }

  static func getPersonCollections(limit: Int = 20, offset: Int = 0) async throws
    -> PagedDTO<PersonDTO>
  {
    let url = BangumiAPI.priv.build("p1/collections/persons")
    let data = try await APIClient.shared.request(
      url: url.appending(queryItems: paginationQueryItems(limit: limit, offset: offset)),
      method: "GET",
      auth: .required)
    let resp: PagedDTO<PersonDTO> = try await APIClient.shared.decodeResponse(data)
    return resp
  }

  static func getSubjectCollections(
    type: CollectionType = .none,
    subjectType: SubjectType = .none,
    since: Int = 0,
    limit: Int = 100,
    offset: Int = 0
  ) async throws -> PagedDTO<SubjectDTO> {
    let url = BangumiAPI.priv.build("p1/collections/subjects")
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
    let data = try await APIClient.shared.request(
      url: url.appending(queryItems: queryItems), method: "GET", auth: .required)
    let resp: PagedDTO<SubjectDTO> = try await APIClient.shared.decodeResponse(data)
    return resp
  }

  private static func paginationQueryItems(limit: Int, offset: Int) -> [URLQueryItem] {
    [
      URLQueryItem(name: "limit", value: String(limit)),
      URLQueryItem(name: "offset", value: String(offset)),
    ]
  }
}
