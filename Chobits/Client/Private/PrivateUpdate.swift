//
//  PrivateUpdate.swift
//  Chobits
//
//  Created by Chuan Chuan on 2024/10/4.
//

import Foundation
import OSLog

extension Chii {
  func clearNotify(ids: [UInt]) async throws {
    Logger.api.info("start clear notify")
    let url = BangumiAPI.priv.build("p1/clear-notify")
    var body: [String: Any] = [:]
    body["id"] = ids
    _ = try await request(url: url, method: "POST", body: body)
    Logger.api.info("finish clear notify")
  }
}
