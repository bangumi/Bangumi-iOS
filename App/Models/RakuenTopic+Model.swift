import Foundation
import OSLog
import SwiftData
import SwiftUI

typealias RakuenSubjectTopicCache = RakuenSubjectTopicCacheV1
typealias RakuenGroupTopicCache = RakuenGroupTopicCacheV1

@Model
final class RakuenSubjectTopicCacheV1 {
  @Attribute(.unique)
  var mode: String

  var items: [SubjectTopicDTO]
  var updatedAt: Date

  init(mode: String, items: [SubjectTopicDTO]) {
    self.mode = mode
    self.items = items
    self.updatedAt = Date()
  }
}

@Model
final class RakuenGroupTopicCacheV1 {
  @Attribute(.unique)
  var mode: String

  var items: [GroupTopicDTO]
  var updatedAt: Date

  init(mode: String, items: [GroupTopicDTO]) {
    self.mode = mode
    self.items = items
    self.updatedAt = Date()
  }
}

typealias HotGroupCache = HotGroupCacheV1

@Model
final class HotGroupCacheV1 {
  @Attribute(.unique)
  var id: String = "hot_groups"

  var items: [SlimGroupDTO]
  var updatedAt: Date

  init(items: [SlimGroupDTO]) {
    self.items = items
    self.updatedAt = Date()
  }
}
