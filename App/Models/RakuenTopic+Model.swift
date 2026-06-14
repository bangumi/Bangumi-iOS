import Foundation

typealias RakuenSubjectTopicCache = BangumiSchemaV3.RakuenSubjectTopicCacheV2
typealias RakuenGroupTopicCache = BangumiSchemaV3.RakuenGroupTopicCacheV2
typealias RakuenGroupCache = BangumiSchemaV3.RakuenGroupCacheV2

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
