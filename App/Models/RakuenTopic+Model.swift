import Foundation

final class RakuenSubjectTopicCache {
  var mode: String

  var itemsData: Data?
  var updatedAt: Date

  init(mode: String, items: [SubjectTopicDTO]) {
    self.mode = mode
    itemsData = PersistedJSON.encode(items)
    updatedAt = Date()
  }
}

final class RakuenGroupTopicCache {
  var mode: String

  var itemsData: Data?
  var updatedAt: Date

  init(mode: String, items: [GroupTopicDTO]) {
    self.mode = mode
    itemsData = PersistedJSON.encode(items)
    updatedAt = Date()
  }
}

final class RakuenGroupCache {
  var id: String

  var itemsData: Data?
  var updatedAt: Date

  init(id: String, items: [SlimGroupDTO]) {
    self.id = id
    itemsData = PersistedJSON.encode(items)
    updatedAt = Date()
  }
}

extension RakuenSubjectTopicCache {
  var items: [SubjectTopicDTO] {
    get { PersistedJSON.decode([SubjectTopicDTO].self, from: itemsData) ?? [] }
    set { itemsData = PersistedJSON.encode(newValue) ?? itemsData }
  }
}

extension RakuenGroupTopicCache {
  var items: [GroupTopicDTO] {
    get { PersistedJSON.decode([GroupTopicDTO].self, from: itemsData) ?? [] }
    set { itemsData = PersistedJSON.encode(newValue) ?? itemsData }
  }
}

extension RakuenGroupCache {
  var items: [SlimGroupDTO] {
    get { PersistedJSON.decode([SlimGroupDTO].self, from: itemsData) ?? [] }
    set { itemsData = PersistedJSON.encode(newValue) ?? itemsData }
  }
}
