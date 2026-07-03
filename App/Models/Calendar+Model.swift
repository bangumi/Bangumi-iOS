import Foundation

final class BangumiCalendar {
  var weekday: Int

  var itemsData: Data?

  init(weekday: Int, items: [BangumiCalendarItemDTO]) {
    self.weekday = weekday
    itemsData = PersistedJSON.encode(items)
  }
}

extension BangumiCalendar {
  var items: [BangumiCalendarItemDTO] {
    get { PersistedJSON.decode([BangumiCalendarItemDTO].self, from: itemsData) ?? [] }
    set { itemsData = PersistedJSON.encode(newValue) ?? itemsData }
  }
}
