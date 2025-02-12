import Foundation

struct SubjectsResponse: Codable {
  var total: Int
  var limit: Int
  var offset: Int
  var data: [SubjectDTOV0]
}

struct SubjectDTOV0: Codable {
  var id: Int
  var type: SubjectType
  var name: String
  var nameCn: String
  var summary: String
  var series: Bool
  var nsfw: Bool
  var locked: Bool
  var date: String?
  var platform: String?
  var images: SubjectImages?
  var volumes: Int
  // var infobox: [String: String]
  var eps: Int
  var rating: SubjectRatingV0
  var collection: SubjectCollection
  var metaTags: [String]
  var tags: [Tag]
}

struct SubjectRatingV0: Codable {
  var count: [String: Int]
  var total: Int
  var score: Float
  var rank: Int
}

struct SubjectsBrowseFilterDTO {
  var cat: SubjectCategory? = nil
  var series: Bool? = nil
  var platform: String = ""
  var sort: String = "rank"
  var year: Int32 = 0
  var month: Int8 = 0

  var description: String {
    var result = ""
    if let cat = cat {
      result += "cat:\(cat.name),"
    }
    if let series = series {
      result += "series:\(series),"
    }
    if !platform.isEmpty {
      result += "platform:\(platform),"
    }
    if !sort.isEmpty {
      result += "sort:\(sort),"
    }
    if year > 0 {
      result += "year:\(year),"
    }
    if month > 0 {
      result += "month:\(month),"
    }
    return result
  }
}

@Observable
final class SubjectsBrowseFilter {
  var cat: SubjectCategory? = nil
  var series: Bool? = nil
  var platform: String = ""
  var sort: String = "rank"
  var year: Int32 = 0
  var month: Int8 = 0

  func dto() -> SubjectsBrowseFilterDTO {
    return SubjectsBrowseFilterDTO(
      cat: cat,
      series: series,
      platform: platform,
      sort: sort,
      year: year,
      month: month
    )
  }
}
