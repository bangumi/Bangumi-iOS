import Foundation
import SwiftData

typealias BangumiCalendar = BangumiSchemaV3.BangumiCalendarV2

extension BangumiCalendar {
  var items: [BangumiCalendarItemDTO] {
    get { PersistedJSON.decode([BangumiCalendarItemDTO].self, from: itemsData) ?? [] }
    set { itemsData = PersistedJSON.encode(newValue) ?? itemsData }
  }
}
