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
    let data = try await self.request(url: pageURL, method: "GET", auth: .required)
    let resp: NotifyResponse = try self.decodeResponse(data)
    Logger.api.info("finish get notify")
    return resp
  }

  func getSubjectTopics(subjectId: UInt, limit: Int, offset: Int = 0) async throws -> SubjectTopicsResponse {
    if self.mock {
      return loadFixture(fixture: "subject_topics.json", target: SubjectTopicsResponse.self)
    }
    Logger.api.info("start get subject topics")
    let url = BangumiAPI.priv.build("p1/subjects/\(subjectId)/topics")
    let queryItems: [URLQueryItem] = [
      URLQueryItem(name: "limit", value: String(limit)),
      URLQueryItem(name: "offset", value: String(offset)),
    ]
    let pageURL = url.appending(queryItems: queryItems)
    let data = try await self.request(url: pageURL, method: "GET")
    let resp: SubjectTopicsResponse = try self.decodeResponse(data)
    Logger.api.info("finish get subject topics")
    return resp
  }

  func getSubjectComments(subjectId: UInt, limit: Int, offset: Int = 0) async throws -> SubjectInterestCommentsResponse {
    if self.mock {
      return loadFixture(fixture: "subject_comments.json", target: SubjectInterestCommentsResponse.self)
    }
    Logger.api.info("start get subject comments")
    let url = BangumiAPI.priv.build("p1/subjects/\(subjectId)/comments")
    let queryItems: [URLQueryItem] = [
      URLQueryItem(name: "limit", value: String(limit)),
      URLQueryItem(name: "offset", value: String(offset)),
    ]
    let pageURL = url.appending(queryItems: queryItems)
    let data = try await self.request(url: pageURL, method: "GET")
    let resp: SubjectInterestCommentsResponse = try self.decodeResponse(data)
    Logger.api.info("finish get subject comments")
    return resp
  }
}
