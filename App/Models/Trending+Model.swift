import Foundation
import SwiftData

typealias TrendingSubject = BangumiSchemaV3.TrendingSubjectV2

extension TrendingSubject {
  var items: [TrendingSubjectDTO] {
    get { PersistedJSON.decode([TrendingSubjectDTO].self, from: itemsData) ?? [] }
    set { itemsData = PersistedJSON.encode(newValue) ?? itemsData }
  }
}
