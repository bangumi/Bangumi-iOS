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

    let item = try await self.getSubject(sid)

    // 对于合并的条目，可能搜索返回的 ID 跟 API 拿到的 ID 不同
    // 我们直接返回 404 防止其他问题
    // 后面可以考虑直接跳转到页面
    if sid != item.id {
      Logger.subject.warning("subject id mismatch: \(sid) != \(item.id)")
      throw ChiiError(message: "这是一个被合并的条目")
    }

    Logger.subject.info("fetched subject: \(item.id)")
    let subject = Subject(item)
    await self.db.insert(subject)
  }

  func loadUserCollection(_ subjectId: UInt) async throws {
    if !self.isAuthenticated {
      return
    }
    let item = try await self.getSubjectCollection(subjectId)
    let collection = UserSubjectCollection(item)
    await self.db.insert(collection)
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
        let collection = UserSubjectCollection(item)
        await self.db.insert(collection)
        if let slim = item.subject {
          let subject = Subject(slim)
          let subjectId = subject.id
          try await self.db.insertIfNeeded(
            data: subject,
            predicate: #Predicate<Subject> {
              $0.id == subjectId
            })
        }
      }
      offset += limit
      if offset > response.total {
        break
      }
    }
    Logger.collection.info("finish update collection for \(type?.name ?? "all")")
  }

  func loadEpisodes(_ subjectId: UInt) async throws {
    guard let subject = try await db.fetchOne(predicate: #Predicate<Subject> { $0.id == subjectId })
    else {
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
        total = response.total
        guard let data = response.data else {
          break
        }
        if data.isEmpty {
          break
        }
        for item in data {
          let episode = Episode(item, subjectId: subjectId)
          await db.insert(episode)
        }
        total = response.total
      } else {
        let response = try await self.getSubjectEpisodes(
          subjectId: subjectId, type: nil, limit: limit, offset: offset)
        if response.data.isEmpty {
          break
        }
        for item in response.data {
          let episode = Episode(item, subjectId: subjectId)
          await db.insert(episode)
        }
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
      let cal = BangumiCalendar(item)
      await db.insert(cal)
      for small in item.items {
        let subject = Subject(small)
        try await db.insertIfNeeded(
          data: subject,
          predicate: #Predicate<Subject> {
            $0.id == small.id
          })
      }
    }
  }
}
