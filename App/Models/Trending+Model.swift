import Foundation

final class TrendingSubject {
  var type: Int

  var itemsData: Data?

  init(type: Int, items: [TrendingSubjectDTO]) {
    self.type = type
    itemsData = PersistedJSON.encode(items)
  }
}

extension TrendingSubject {
  var items: [TrendingSubjectDTO] {
    get { PersistedJSON.decode([TrendingSubjectDTO].self, from: itemsData) ?? [] }
    set { itemsData = PersistedJSON.encode(newValue) ?? itemsData }
  }
}
