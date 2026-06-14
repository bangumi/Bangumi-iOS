import Foundation

typealias Draft = BangumiSchemaV3.DraftV1

extension Draft {
  func update(content: String) {
    self.content = content
    self.updatedAt = Int(Date().timeIntervalSince1970)
  }
}
