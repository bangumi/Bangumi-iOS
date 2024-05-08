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
  var id: UInt
  var weekday: Weekday
  var items: [SmallSubject]

  init(id: UInt, weekday: Weekday, items: [SmallSubject]) {
    self.id = id
    self.weekday = weekday
    self.items = items
  }

  init(_ item: BangumiCalendarItem) {
    self.id = item.weekday.id
    self.weekday = item.weekday
    self.items = item.items
  }
}
