import Foundation
import OSLog
import SwiftData
import SwiftUI

typealias TrendingSubject = TrendingSubjectV1

@Model
final class TrendingSubjectV1 {
  @Attribute(.unique)
  var type: Int

  var items: [TrendingSubjectDTO]

  init(type: Int, items: [TrendingSubjectDTO]) {
    self.type = type
    self.items = items
  }
}
