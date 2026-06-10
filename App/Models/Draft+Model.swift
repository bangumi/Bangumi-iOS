import Foundation
import SwiftData

typealias Draft = BangumiSchemaV2.DraftV1

extension Draft {
    func update(content: String) {
        self.content = content
        self.updatedAt = Int(Date().timeIntervalSince1970)
    }
}
