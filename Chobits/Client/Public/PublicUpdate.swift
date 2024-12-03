//
//  PublicUpdate.swift
//  Chobits
//
//  Created by Chuan Chuan on 2024/5/4.
//

import Foundation
import OSLog
import SwiftData

extension Chii {
  func updateBookCollection(subjectId: Int, eps: Int?, vols: Int?) async throws {
    if self.mock {
      return
    }
    Logger.api.info(
      "start update subject collection: \(subjectId), eps: \(eps.debugDescription), vols: \(vols.debugDescription)"
    )
    let url = BangumiAPI.pub.build("v0/users/-/collections/\(subjectId)")
    var body: [String: Any] = [:]
    if let epStatus = eps {
      body["ep_status"] = epStatus
    }
    if let volStatus = vols {
      body["vol_status"] = volStatus
    }
    if body.count > 0 {
      _ = try await self.request(url: url, method: "POST", body: body, auth: .required)
    }
    Logger.api.info(
      "finish update subject collection: \(subjectId), eps: \(eps.debugDescription), vols: \(vols.debugDescription)"
    )
    _ = try await self.loadUserSubjectCollection(subjectId)
  }

  func updateSubjectCollection(
    subjectId: Int, type: CollectionType?, rate: Int?, comment: String?,
    priv: Bool?, tags: [String]?
  ) async throws {
    if self.mock {
      return
    }
    Logger.api.info("start update subject collection: \(subjectId)")
    let url = BangumiAPI.pub.build("v0/users/-/collections/\(subjectId)")
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
      _ = try await self.request(url: url, method: "POST", body: body, auth: .required)
    }
    Logger.api.info("finish update subject collection: \(subjectId)")
    _ = try await self.loadUserSubjectCollection(subjectId)
  }

  func updateSubjectEpisodeCollection(
    subjectId: Int, updateTo: Float, type: EpisodeCollectionType
  ) async throws {
    if self.mock {
      return
    }
    let db = try self.getDB()
    Logger.api.info(
      "start update subject episode collection: \(subjectId), -> \(updateTo) to \(type.description)"
    )

    let episodeIds = try await db.getEpisodeIDs(subjectId: subjectId, sort: updateTo)
    let url = BangumiAPI.pub.build("v0/users/-/collections/\(subjectId)/episodes")
    let body: [String: Any] = [
      "episode_id": episodeIds,
      "type": type.rawValue,
    ]
    _ = try await self.request(url: url, method: "PATCH", body: body, auth: .required)
    Logger.api.info("finish update subject episode collection: \(subjectId), \(episodeIds)")

    try await db.updateEpisodeCollections(subjectId: subjectId, sort: updateTo, type: type)
    try await db.commit()
    _ = try await self.loadUserSubjectCollection(subjectId)
  }

  func updateEpisodeCollection(subjectId: Int, episodeId: Int, type: EpisodeCollectionType)
    async throws
  {
    if self.mock {
      return
    }
    let db = try self.getDB()
    Logger.api.info("start update episode collection: \(episodeId)")
    let url = BangumiAPI.pub.build(
      "v0/users/-/collections/-/episodes/\(episodeId)")
    let body: [String: Any] = [
      "type": type.rawValue
    ]
    _ = try await self.request(url: url, method: "PUT", body: body, auth: .required)
    Logger.api.info("finish update episode collection: \(episodeId)")

    try await db.updateEpisodeCollection(subjectId: subjectId, episodeId: episodeId, type: type)
    try await db.commit()
    _ = try await self.loadUserSubjectCollection(subjectId)
  }
}
