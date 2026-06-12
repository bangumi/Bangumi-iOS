import Foundation

enum DiscoveryService {
  static func getCalendar() async throws -> BangumiCalendarDTO {
    let url = BangumiAPI.priv.build("p1/calendar")
    let data = try await APIClient.shared.request(url: url, method: "GET")
    let calendars: BangumiCalendarDTO = try await APIClient.shared.decodeResponse(data)
    return calendars
  }

  static func getTrendingSubjects(
    type: SubjectType, limit: Int = 12, offset: Int = 0
  ) async throws -> PagedDTO<TrendingSubjectDTO> {
    if await AppContext.shared.isMock {
      return loadFixture(
        fixture: "trending_subjects_anime.json", target: PagedDTO<TrendingSubjectDTO>.self)
    }
    let url = BangumiAPI.priv.build("p1/trending/subjects")
    let queryItems: [URLQueryItem] = [
      URLQueryItem(name: "type", value: String(type.rawValue)),
      URLQueryItem(name: "limit", value: String(limit)),
      URLQueryItem(name: "offset", value: String(offset)),
    ]
    let pageURL = url.appending(queryItems: queryItems)
    let data = try await APIClient.shared.request(url: pageURL, method: "GET")
    let resp: PagedDTO<TrendingSubjectDTO> = try await APIClient.shared.decodeResponse(data)
    return resp
  }
}
