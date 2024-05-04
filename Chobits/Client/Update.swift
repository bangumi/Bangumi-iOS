//
//  Update.swift
//  Chobits
//
//  Created by Chuan Chuan on 2024/5/4.
//

import Foundation

extension ChiiClient {
  // update progress for books
  func updateSubjectCollection(sid: UInt, eps: UInt?, vols: UInt?) async throws
    -> UserSubjectCollection
  {
    if self.mock != nil {
      return try await getSubjectCollection(sid: sid)
    }
    let url = self.apiBase.appendingPathComponent("v0/users/-/collections/\(sid)")
    var body: [String: Any] = [:]
    if let epStatus = eps {
      body["ep_status"] = epStatus
    }
    if let volStatus = vols {
      body["vol_status"] = volStatus
    }
    if body.count > 0 {
      _ = try await self.request(url: url, method: "POST", body: body, authorized: true)
    }
    return try await getSubjectCollection(sid: sid)
  }

  func updateSubjectCollection(
    sid: UInt, type: CollectionType?, rate: UInt8?, comment: String?, priv: Bool?, tags: [String]?
  ) async throws -> UserSubjectCollection {
    if self.mock != nil {
      return try await getSubjectCollection(sid: sid)
    }
    let url = self.apiBase.appendingPathComponent("v0/users/-/collections/\(sid)")
    var body: [String: Any] = [:]
    if let type = type {
      body["type"] = type.rawValue
    }
    if let rate = rate {
      body["rate"] = rate
    }
    if let comment = comment {
      body["comment"] = comment
    }
    if let priv = priv {
      body["private"] = priv
    }
    if let tags = tags {
      body["tags"] = tags
    }
    if body.count > 0 {
      _ = try await self.request(url: url, method: "POST", body: body, authorized: true)
    }
    return try await getSubjectCollection(sid: sid)
  }

  func updateSubjectEpisodeCollection(
    subjectId: UInt, episodeIds: [UInt], type: EpisodeCollectionType
  ) async throws {
    if self.mock != nil {
      return
    }
    let url = self.apiBase
      .appendingPathComponent("v0/users/-/collections/\(subjectId)/episodes")
    let body: [String: Any] = [
      "episode_id": episodeIds,
      "type": type.rawValue,
    ]
    _ = try await self.request(url: url, method: "PATCH", body: body, authorized: true)
  }

  func updateEpisodeCollection(episodeId: UInt, type: EpisodeCollectionType) async throws {
    if self.mock != nil {
      return
    }
    let url = self.apiBase.appendingPathComponent("v0/users/-/collections/-/episodes/\(episodeId)")
    let body: [String: Any] = [
      "type": type.rawValue
    ]
    _ = try await self.request(url: url, method: "PUT", body: body, authorized: true)
  }

}
