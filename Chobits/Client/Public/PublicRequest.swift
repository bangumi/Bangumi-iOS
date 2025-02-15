import Foundation

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
