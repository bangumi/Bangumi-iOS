import Foundation
import OSLog

// extension Chii {
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
// }

// struct SubjectsBrowseFilterDTO {
//   var cat: SubjectCategory? = nil
//   var series: Bool? = nil
//   var platform: String = ""
//   var sort: String = "rank"
//   var year: Int32 = 0
//   var month: Int8 = 0

//   var description: String {
//     var result = ""
//     if let cat = cat {
//       result += "cat:\(cat.name),"
//     }
//     if let series = series {
//       result += "series:\(series),"
//     }
//     if !platform.isEmpty {
//       result += "platform:\(platform),"
//     }
//     if !sort.isEmpty {
//       result += "sort:\(sort),"
//     }
//     if year > 0 {
//       result += "year:\(year),"
//     }
//     if month > 0 {
//       result += "month:\(month),"
//     }
//     return result
//   }
// }

// @Observable
// final class SubjectsBrowseFilter {
//   var cat: SubjectCategory? = nil
//   var series: Bool? = nil
//   var platform: String = ""
//   var sort: String = "rank"
//   var year: Int32 = 0
//   var month: Int8 = 0

//   func dto() -> SubjectsBrowseFilterDTO {
//     return SubjectsBrowseFilterDTO(
//       cat: cat,
//       series: series,
//       platform: platform,
//       sort: sort,
//       year: year,
//       month: month
//     )
//   }
// }
