import Foundation
import OSLog

extension Chii {
  func clearNotice(ids: [Int]) async throws {
    let url = BangumiAPI.priv.build("p1/clear-notify")
    var body: [String: Any] = [:]
    body["id"] = ids
    _ = try await self.request(url: url, method: "POST", body: body, auth: .required)
  }
}
