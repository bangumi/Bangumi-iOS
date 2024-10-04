//
//  PrivateFetch.swift
//  Chobits
//
//  Created by Chuan Chuan on 2024/10/4.
//

import Foundation
import OSLog

extension Chii {
  func getNotify(limit: Int? = nil, unread: Bool? = nil) async throws -> NotifyResponse {
    Logger.api.info("start get notify")
    let url = BangumiAPI.priv.build("p1/notify")
    var queryItems: [URLQueryItem] = []
    if let limit = limit {
      queryItems.append(URLQueryItem(name: "limit", value: String(limit)))
    }
    if let unread = unread {
      queryItems.append(URLQueryItem(name: "unread", value: String(unread)))
    }
    let pageURL = url.appending(queryItems: queryItems)
    let data = try await request(url: pageURL, method: "GET")
    let resp: NotifyResponse = try self.decodeResponse(data)
    Logger.api.info("finish get notify")
    return resp
  }
}
