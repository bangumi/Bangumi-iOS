import Foundation

enum SearchService {
  static func searchSubjects(
    keyword: String, type: SubjectType = .none, limit: Int = 10, offset: Int = 0
  ) async throws -> PagedDTO<SlimSubjectDTO> {
    let queries = paginationQueryItems(limit: limit, offset: offset)
    let url = BangumiURL.next(path: "p1/search/subjects").appending(queryItems: queries)
    var body: [String: Any] = [
      "keyword": keyword,
      "sort": "match",
    ]
    if type != .none {
      body["filter"] = [
        "type": [type.rawValue]
      ]
    }
    let data = try await APIClient.shared.request(url: url, method: "POST", body: body)
    let resp: PagedDTO<SlimSubjectDTO> = try await APIClient.shared.decodeResponse(data)
    return resp
  }

  static func searchCharacters(keyword: String, limit: Int = 10, offset: Int = 0) async throws
    -> PagedDTO<SlimCharacterDTO>
  {
    let url = BangumiURL.next(path: "p1/search/characters").appending(
      queryItems: paginationQueryItems(limit: limit, offset: offset))
    let body: [String: Any] = ["keyword": keyword]
    let data = try await APIClient.shared.request(url: url, method: "POST", body: body)
    let resp: PagedDTO<SlimCharacterDTO> = try await APIClient.shared.decodeResponse(data)
    return resp
  }

  static func searchPersons(keyword: String, limit: Int = 10, offset: Int = 0) async throws
    -> PagedDTO<SlimPersonDTO>
  {
    let url = BangumiURL.next(path: "p1/search/persons").appending(
      queryItems: paginationQueryItems(limit: limit, offset: offset))
    let body: [String: Any] = ["keyword": keyword]
    let data = try await APIClient.shared.request(url: url, method: "POST", body: body)
    let resp: PagedDTO<SlimPersonDTO> = try await APIClient.shared.decodeResponse(data)
    return resp
  }

  private static func paginationQueryItems(limit: Int, offset: Int) -> [URLQueryItem] {
    [
      URLQueryItem(name: "limit", value: String(limit)),
      URLQueryItem(name: "offset", value: String(offset)),
    ]
  }
}
