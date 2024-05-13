//
//  Calendar.swift
//  Chobits
//
//  Created by Chuan Chuan on 2024/5/8.
//

import Foundation
import SwiftData

@Model
final class BangumiCalendar {
  @Attribute(.unique)
  var weekdayId: UInt
  var weekday: Weekday
  var items: [SmallSubject]

  init(weekdayId: UInt, weekday: Weekday, items: [SmallSubject]) {
    self.weekdayId = weekdayId
    self.weekday = weekday
    self.items = items
  }

  init(_ item: BangumiCalendarDTO) {
    self.weekdayId = item.weekday.id
    self.weekday = item.weekday
    self.items = item.items
  }
}
