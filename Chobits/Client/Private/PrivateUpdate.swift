//
//  PrivateUpdate.swift
//  Chobits
//
//  Created by Chuan Chuan on 2024/10/4.
//

import Foundation
import OSLog

extension Chii {
  func clearNotice(ids: [Int]) async throws {
    Logger.api.info("start clear notify")
    let url = BangumiAPI.priv.build("p1/clear-notify")
    var body: [String: Any] = [:]
    body["id"] = ids
    _ = try await self.request(url: url, method: "POST", body: body, auth: .required)
    Logger.api.info("finish clear notify")
  }
}
