import Foundation
import OSLog
import SwiftData
import SwiftUI

typealias BangumiCalendar = BangumiCalendarV1

@Model
final class BangumiCalendarV1 {
  @Attribute(.unique)
  var weekday: Int

  var items: [BangumiCalendarItemDTO]

  init(weekday: Int, items: [BangumiCalendarItemDTO]) {
    self.weekday = weekday
    self.items = items
  }
}
