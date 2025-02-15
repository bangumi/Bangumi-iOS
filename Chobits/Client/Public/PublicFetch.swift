import Foundation
import OSLog

extension Chii {
  // func getSubjects(
  //   type: SubjectType, filter: SubjectsBrowseFilterDTO, limit: Int = 10, offset: Int = 0
  // ) async throws -> SubjectsResponse {
  //   if self.mock {
  //     return loadFixture(fixture: "subjects.json", target: SubjectsResponse.self)
  //   }
  //   var queries: [URLQueryItem] = [
  //     URLQueryItem(name: "type", value: String(type.rawValue)),
  //     URLQueryItem(name: "limit", value: String(limit)),
  //     URLQueryItem(name: "offset", value: String(offset)),
  //   ]
  //   if let cat = filter.cat {
  //     queries.append(URLQueryItem(name: "cat", value: String(cat.id)))
  //   }
  //   if type == .book, let series = filter.series {
  //     queries.append(URLQueryItem(name: "series", value: String(series)))
  //   }
  //   if type == .game, !filter.platform.isEmpty {
  //     queries.append(URLQueryItem(name: "platform", value: filter.platform))
  //   }
  //   if !filter.sort.isEmpty {
  //     queries.append(URLQueryItem(name: "sort", value: filter.sort))
  //   }
  //   if filter.year > 0 {
  //     queries.append(URLQueryItem(name: "year", value: String(filter.year)))
  //     if filter.month > 0 {
  //       queries.append(URLQueryItem(name: "month", value: String(filter.month)))
  //     }
  //   }
  //   let url = BangumiAPI.pub.build("v0/subjects")
  //     .appending(queryItems: queries)
  //   let data = try await self.request(url: url, method: "GET")
  //   let response: SubjectsResponse = try self.decodeResponse(data)
  //   return response
  // }
}
