import Foundation

final class Draft {
  var draftId: Int64?

  var content: String
  var type: String
  var createdAt: Int
  var updatedAt: Int

  init(draftId: Int64? = nil, type: String, content: String) {
    self.draftId = draftId
    self.content = content
    self.type = type
    createdAt = Int(Date().timeIntervalSince1970)
    updatedAt = Int(Date().timeIntervalSince1970)
  }
}

extension Draft {
  func update(content: String) {
    self.content = content
    self.updatedAt = Int(Date().timeIntervalSince1970)
  }
}
