//
//  Load.swift
//  Chobits
//
//  Created by Chuan Chuan on 2024/5/7.
//

import Foundation
import OSLog
import SwiftData
import SwiftUI

extension Chii {
  func loadCalendar() async throws {
    let db = try self.getDB()
    let response = try await self.getCalendar()
    for item in response {
      try await db.saveCalendarItem(item)
    }
    try await db.commit()
  }

  func loadSubject(_ sid: Int) async throws {
    let db = try self.getDB()
    let item = try await self.getSubject(sid)

    // 对于合并的条目，可能搜索返回的 ID 跟 API 拿到的 ID 不同
    // 我们直接返回 404 防止其他问题
    // 后面可以考虑直接跳转到页面
    if sid != item.id {
      Logger.subject.warning("subject id mismatch: \(sid) != \(item.id)")
      throw ChiiError(message: "这是一个被合并的条目")
    }

    try await db.saveSubject(item)
    try await db.commit()
    await self.index([item.searchable()])
  }

  func loadUserSubjectCollection(_ subjectId: Int) async throws {
    if !self.isAuthenticated() {
      return
    }
    let db = try self.getDB()
    do {
      let item = try await self.getUserSubjectCollection(subjectId)
      try await db.saveUserSubjectCollection(item)
      await self.index([item.subject.searchable()])
    } catch ChiiError.notFound(_) {
      Logger.subject.warning("collection not found for subject: \(subjectId)")
      try await db.deleteUserCollection(subjectId: subjectId)
    }
    try await db.commit()
  }

  func loadSubjectCharacters(_ subjectId: Int) async throws {
    let db = try self.getDB()
    let resp = try await Chii.shared.getSubjectCharacters(subjectId, limit: 10)
    try await db.saveSubjectCharacters(subjectId, resp.data)
    try await db.commit()
  }

  func loadSubjectOffprints(_ subjectId: Int) async throws {
    let db = try self.getDB()
    let resp = try await Chii.shared.getSubjectRelations(
      subjectId, offprint: true, limit: 100)
    try await db.saveSubjectOffprints(subjectId, resp.data)
    try await db.commit()
  }

  func loadSubjectRelations(_ subjectId: Int) async throws {
    let db = try self.getDB()
    let resp = try await Chii.shared.getSubjectRelations(subjectId, limit: 10)
    try await db.saveSubjectRelations(subjectId, resp.data)
    try await db.commit()
  }

  func loadSubjectRecs(_ subjectId: Int) async throws {
    let db = try self.getDB()
    let resp = try await Chii.shared.getSubjectRecs(subjectId, limit: 10)
    try await db.saveSubjectRecs(subjectId, resp.data)
    try await db.commit()
  }

  func loadSubjectReviews(_ subjectId: Int) async throws {
    let db = try self.getDB()
    let resp = try await Chii.shared.getSubjectReviews(subjectId, limit: 5)
    try await db.saveSubjectReviews(subjectId, resp.data)
    try await db.commit()
  }

  func loadSubjectTopics(_ subjectId: Int) async throws {
    let db = try self.getDB()
    let resp = try await Chii.shared.getSubjectTopics(subjectId, limit: 5)
    try await db.saveSubjectTopics(subjectId, resp.data)
    try await db.commit()
  }

  func loadSubjectComments(_ subjectId: Int) async throws {
    let db = try self.getDB()
    let resp = try await Chii.shared.getSubjectComments(subjectId, limit: 10)
    try await db.saveSubjectComments(subjectId, resp.data)
    try await db.commit()
  }

  func loadEpisodes(_ subjectId: Int) async throws {
    let db = try self.getDB()
    let type = try await db.getSubjectType(subjectId)
    switch type {
    case .anime, .music, .real:
      break
    default:
      return
    }
    var offset: Int = 0
    let limit: Int = 1000
    var total: Int = 0

    if self.isAuthenticated() {
      var items: [EpisodeCollectionDTO] = []
      while true {
        let response = try await self.getEpisodeCollections(
          subjectId, limit: limit, offset: offset)
        total = response.total
        if response.data.isEmpty {
          break
        }
        for item in response.data {
          items.append(item)
        }
        offset += limit
        if offset > total {
          break
        }
      }
      for item in items {
        try await db.saveEpisode(item)
      }
      try await db.commit()
    } else {
      var items: [EpisodeDTO] = []
      while true {
        let response = try await self.getSubjectEpisodes(
          subjectId, limit: limit, offset: offset)
        total = response.total
        if response.data.isEmpty {
          break
        }
        for item in response.data {
          items.append(item)
        }
        offset += limit
        if offset > total {
          break
        }
      }
      for item in items {
        try await db.saveEpisode(item)
      }
      try await db.commit()
    }
  }
}

extension Chii {
  func loadCharacter(_ cid: Int) async throws {
    let db = try self.getDB()
    let item = try await self.getCharacter(cid)
    if cid != item.id {
      Logger.subject.warning("character id mismatch: \(cid) != \(item.id)")
      throw ChiiError(message: "这是一个被合并的角色")
    }
    try await db.saveCharacter(item)
    try await db.commit()
    await self.index([item.searchable()])
  }

  func loadPerson(_ pid: Int) async throws {
    let db = try self.getDB()
    let item = try await self.getPerson(pid)
    if pid != item.id {
      Logger.subject.warning("person id mismatch: \(pid) != \(item.id)")
      throw ChiiError(message: "这是一个被合并的人物")
    }
    try await db.savePerson(item)
    try await db.commit()
    await self.index([item.searchable()])
  }
}
