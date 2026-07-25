import Foundation

struct UserIndexCache {
  var userID: Int
  var itemsData: Data?
  var updatedAt: Date

  init(userID: Int, items: [SlimIndexDTO]) {
    self.userID = userID
    itemsData = PersistedJSON.encode(items)
    updatedAt = Date()
  }

  var items: [SlimIndexDTO]? {
    PersistedJSON.decode([SlimIndexDTO].self, from: itemsData)
  }
}
