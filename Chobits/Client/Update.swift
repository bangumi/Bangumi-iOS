//
//  Update.swift
//  Chobits
//
//  Created by Chuan Chuan on 2024/5/4.
//

import Foundation
import OSLog
import SwiftData

extension ChiiClient {
  func updateBookCollection(sid: UInt, eps: UInt?, vols: UInt?) async throws {
    if self.mock != nil {
      return
    }
    Logger.api.info(
      "start update subject collection: \(sid), eps: \(eps.debugDescription), vols: \(vols.debugDescription)"
    )
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
    Logger.api.info(
      "finish update subject collection: \(sid), eps: \(eps.debugDescription), vols: \(vols.debugDescription)"
    )
    let item = try await getSubjectCollection(sid)
    let collect = UserSubjectCollection(item)
    await self.db.insert(collect)
    try await self.db.save()
  }

  func updateSubjectCollection(
    sid: UInt, type: CollectionType?, rate: UInt8?, comment: String?,
    priv: Bool?, tags: [String]?
  ) async throws {
    if self.mock != nil {
      return
    }
    Logger.api.info("start update subject collection: \(sid)")
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
    Logger.api.info("finish update subject collection: \(sid)")
    let item = try await getSubjectCollection(sid)
    let collect = UserSubjectCollection(item)
    await self.db.insert(collect)
    try await self.db.save()
  }

  func updateSubjectEpisodeCollection(
    subjectId: UInt, updateTo: Float, type: EpisodeCollectionType
  ) async throws {
    if self.mock != nil {
      return
    }
    Logger.api.info(
      "start update subject episode collection: \(subjectId), -> \(updateTo) to \(type.description)"
    )
    let predicate = #Predicate<Episode> {
      $0.subjectId == subjectId && $0.sort <= updateTo
    }
    let episodes = try await db.fetchData(predicate: predicate)
    let episodeIds = episodes.map { $0.episodeId }
    let url = self.apiBase
      .appendingPathComponent("v0/users/-/collections/\(subjectId)/episodes")
    let body: [String: Any] = [
      "episode_id": episodeIds,
      "type": type.rawValue,
    ]
    _ = try await self.request(url: url, method: "PATCH", body: body, authorized: true)
    Logger.api.info("finish update subject episode collection: \(subjectId), \(episodeIds)")
    try await db.update(
      predicate: predicate,
      update: {
        $0.collection = type.rawValue
      })
    try await db.save()
  }

  func updateEpisodeCollection(episodeId: UInt, type: EpisodeCollectionType)
    async throws
  {
    if self.mock != nil {
      return
    }
    Logger.api.info("start update episode collection: \(episodeId)")
    let url = self.apiBase.appendingPathComponent("v0/users/-/collections/-/episodes/\(episodeId)")
    let body: [String: Any] = [
      "type": type.rawValue
    ]
    _ = try await self.request(url: url, method: "PUT", body: body, authorized: true)
    Logger.api.info("finish update episode collection: \(episodeId)")
    try await db.update(
      predicate: #Predicate<Episode> {
        $0.episodeId == episodeId
      },
      update: {
        $0.collection = type.rawValue
      })
    try await db.save()
  }
}
