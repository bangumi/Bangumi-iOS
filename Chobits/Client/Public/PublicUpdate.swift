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
  func updateBookCollection(sid: UInt, eps: UInt?, vols: UInt?) async throws {
    if self.mock {
      return
    }
    let db = try self.getDB()
    Logger.api.info(
      "start update subject collection: \(sid), eps: \(eps.debugDescription), vols: \(vols.debugDescription)"
    )
    let url = BangumiAPI.pub.build("v0/users/-/collections/\(sid)")
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
      "finish update subject collection: \(sid), eps: \(eps.debugDescription), vols: \(vols.debugDescription)"
    )
    try await db.updateUserCollection(sid: sid, eps: eps, vols: vols)
    try await db.commit()
  }

  func updateSubjectCollection(
    sid: UInt, type: CollectionType?, rate: UInt8?, comment: String?,
    priv: Bool?, tags: [String]?
  ) async throws {
    if self.mock {
      return
    }
    Logger.api.info("start update subject collection: \(sid)")
    let url = BangumiAPI.pub.build("v0/users/-/collections/\(sid)")
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
    Logger.api.info("finish update subject collection: \(sid)")

    let db = try self.getDB()
    try await db.updateUserCollection(
        sid: sid, type: type, rate: rate, comment: comment, priv: priv, tags: tags)
    try await db.commit()
  }

  func updateSubjectEpisodeCollection(
    subjectId: UInt, updateTo: Float, type: EpisodeCollectionType
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
  }

  func updateEpisodeCollection(subjectId: UInt, episodeId: UInt, type: EpisodeCollectionType)
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
    try await self.loadUserCollection(subjectId)
  }
}
