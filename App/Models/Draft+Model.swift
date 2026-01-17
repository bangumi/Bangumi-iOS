import Foundation
import OSLog
import SwiftData
import SwiftUI

typealias Draft = DraftV1

@Model
final class DraftV1 {
  var content: String
  var type: String
  var createdAt: Int
  var updatedAt: Int

  init(type: String, content: String) {
    self.content = content
    self.type = type
    self.createdAt = Int(Date().timeIntervalSince1970)
    self.updatedAt = Int(Date().timeIntervalSince1970)
  }

  func update(content: String) {
    self.content = content
    self.updatedAt = Int(Date().timeIntervalSince1970)
  }
}
