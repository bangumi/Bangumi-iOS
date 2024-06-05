//
//  Request.swift
//  Chobits
//
//  Created by Chuan Chuan on 2024/6/5.
//

import Foundation

@Observable
class SubjectsBrowseFilter {
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
