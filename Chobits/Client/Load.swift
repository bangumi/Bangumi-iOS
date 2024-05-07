//
//  Load.swift
//  Chobits
//
//  Created by Chuan Chuan on 2024/5/7.
//

import Foundation
import OSLog
import SwiftData

extension ChiiClient {
  func loadSubject(_ sid: UInt) async throws {
    Logger.api.info("loading subject: \(sid)")
    do {
      let item = try await self.getSubject(sid)

      // 对于合并的条目，可能搜索返回的 ID 跟 API 拿到的 ID 不同
      // 我们直接返回 404 防止其他问题
      // 后面可以考虑直接跳转到页面
      if sid != item.id {
        Logger.subject.warning("subject id mismatch: \(sid) != \(item.id)")
        throw ChiiError(message: "这是一个被合并的条目")
      }

      Logger.subject.info("fetched subject: \(item.id)")
      let subject = Subject(item: item)
      await self.db.insert(subject)
      try await self.db.save()
    } catch ChiiError.notFound(_) {
      Logger.subject.warning("subject not found: \(sid)")
      try await self.db.remove(
        #Predicate<Subject> {
          $0.id == sid
        })
      try await self.db.save()
    } catch {
      throw error
    }
  }

  func loadUserCollection(_ subjectId: UInt) async throws {
    if !self.isAuthenticated {
      return
    }
    do {
      let item = try await self.getSubjectCollection(subjectId)
      let collection = UserSubjectCollection(item: item)
      await self.db.insert(collection)
      try await self.db.save()
    } catch ChiiError.notFound(_) {
      Logger.collection.warning("collection not found: \(subjectId)")
      try await self.db.remove(
        #Predicate<UserSubjectCollection> {
          $0.subjectId == subjectId
        })
      try await self.db.save()
    } catch {
      throw error
    }
  }

  func loadUserCollections(type: SubjectType?) async throws {
    Logger.collection.info("start update collection for \(type?.name ?? "all")")
    var offset: Int = 0
    let limit: Int = 1000
    while true {
      let response = try await self.getSubjectCollections(
        subjectType: type, limit: limit, offset: offset)
      if response.data.isEmpty {
        break
      }
      for item in response.data {
        let collection = UserSubjectCollection(item: item)
        await self.db.insert(collection)
      }
      offset += limit
      if offset > response.total {
        break
      }
    }
    try await self.db.save()
    Logger.collection.info("finish update collection for \(type?.name ?? "all")")
  }

  func loadEpisodes(_ subjectId: UInt) async throws {
    guard let subject = try await db.fetchOne(predicate: #Predicate<Subject> { $0.id == subjectId }) else {
      Logger.subject.error("subject \(subjectId) not found for loading episode")
      return
    }
    switch subject.typeEnum {
    case .anime, .real:
      break
    default:
      return
    }
    var offset: Int = 0
    let limit: Int = 1000
    while true {
      var total: Int = 0
      if self.isAuthenticated {
        let response = try await self.getEpisodeCollections(
          subjectId: subjectId, type: nil, limit: limit, offset: offset)
        if response.data.isEmpty {
          break
        }
        for item in response.data {
          let episode = Episode(collection: item, subjectId: subjectId)
          await db.insert(episode)
        }
        try await db.save()
        total = response.total
      } else {
        let response = try await self.getSubjectEpisodes(
          subjectId: subjectId, type: nil, limit: limit, offset: offset)
        if response.data.isEmpty {
          break
        }
        for item in response.data {
          let episode = Episode(item: item, subjectId: subjectId)
          await db.insert(episode)
        }
        try await db.save()
        total = response.total
      }
      offset += limit
      if offset > total {
        break
      }
    }
  }

  func loadCalendar() async throws {
    let response = try await self.getCalendar()
    for item in response {
      Logger.api.info("processing calendar: \(item.weekday.en)")
      let cal = BangumiCalendar(item: item)
      await db.insert(cal)
      for small in item.items {
        let subject = Subject(small: small)
        try await db.insertIfNeeded(
          data: subject,
          predicate: #Predicate<Subject> {
            $0.id == small.id
          })
      }
    }
    try await db.save()
  }
}
