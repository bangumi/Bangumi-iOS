import Foundation
import OSLog
import SwiftData
import SwiftUI

extension Chii {
  func loadUser(_ username: String) async throws -> UserDTO {
    let db = try self.getDB()
    let item = try await self.getUser(username)
    try await db.saveUser(item)
    try await db.commit()
    return item
  }

  func loadCalendar() async throws {
    let db = try self.getDB()
    let response = try await self.getCalendar()
    for (weekday, items) in response {
      guard let weekday = Int(weekday) else {
        Logger.api.error("invalid weekday: \(weekday)")
        continue
      }
      try await db.saveCalendarItem(weekday: weekday, items: items)
    }
    try await db.commit()
  }

  func loadTrendingSubjects(type: SubjectType) async throws {
    let db = try self.getDB()
    let response = try await self.getTrendingSubjects(type: type)
    try await db.saveTrendingSubjects(type: type.rawValue, items: response.data)
    try await db.commit()
  }

  func loadSubject(_ sid: Int) async throws -> SubjectDTO {
    let db = try self.getDB()
    let item = try await self.getSubject(sid)

    // 对于合并的条目，可能搜索返回的 ID 跟 API 拿到的 ID 不同
    // 我们直接返回 404 防止其他问题
    // 后面可以考虑直接跳转到页面
    if sid != item.id {
      Logger.api.warning("subject id mismatch: \(sid) != \(item.id)")
      throw ChiiError(message: "这是一个被合并的条目")
    }

    try await db.saveSubject(item)
    if item.interest != nil {
      await self.index([item.searchable()])
    }
    try await db.commit()
    return item
  }

  func loadSubjectDetails(_ subjectId: Int, offprints: Bool, social: Bool) async throws {
    let db = try self.getDB()
    await withThrowingTaskGroup(of: Void.self) { group in
      group.addTask {
        let response = try await self.getSubjectCharacters(subjectId, limit: 12)
        try await db.saveSubjectCharacters(subjectId: subjectId, items: response.data)
      }
      if offprints {
        group.addTask {
          let response = try await self.getSubjectRelations(
            subjectId, offprint: true, limit: 100)
          try await db.saveSubjectOffprints(subjectId: subjectId, items: response.data)
        }
      }
      group.addTask {
        let response = try await self.getSubjectRelations(subjectId, limit: 10)
        try await db.saveSubjectRelations(subjectId: subjectId, items: response.data)
      }
      group.addTask {
        let response = try await self.getSubjectRecs(subjectId, limit: 10)
        try await db.saveSubjectRecs(subjectId: subjectId, items: response.data)
      }
      if social {
        group.addTask {
          let response = try await self.getSubjectReviews(subjectId, limit: 5)
          try await db.saveSubjectReviews(subjectId: subjectId, items: response.data)
        }
        group.addTask {
          let response = try await self.getSubjectTopics(subjectId, limit: 5)
          try await db.saveSubjectTopics(subjectId: subjectId, items: response.data)
        }
        group.addTask {
          let response = try await self.getSubjectComments(subjectId, limit: 10)
          try await db.saveSubjectComments(subjectId: subjectId, items: response.data)
        }
      }
    }
    try await db.commit()
  }

  func loadEpisodes(_ subjectId: Int) async throws {
    let db = try self.getDB()
    var offset: Int = 0
    let limit: Int = 1000
    var total: Int = 0
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

  func loadEpisode(_ episodeId: Int) async throws {
    let db = try self.getDB()
    let item = try await self.getEpisode(episodeId)
    try await db.saveEpisode(item)
    try await db.commit()
  }
}

extension Chii {
  func loadCharacter(_ cid: Int) async throws {
    let db = try self.getDB()
    let item = try await self.getCharacter(cid)
    if cid != item.id {
      Logger.api.warning("character id mismatch: \(cid) != \(item.id)")
      throw ChiiError(message: "这是一个被合并的角色")
    }
    try await db.saveCharacter(item)
    if item.collectedAt != nil {
      await self.index([item.searchable()])
    }
    try await db.commit()
  }

  func loadCharacterDetails(_ characterId: Int) async throws {
    let db = try self.getDB()
    await withThrowingTaskGroup(of: Void.self) { group in
      group.addTask {
        let response = try await self.getCharacterCasts(characterId, limit: 5)
        try await db.saveCharacterCasts(characterId: characterId, items: response.data)
      }
    }
    try await db.commit()
  }

  func loadPerson(_ pid: Int) async throws {
    let db = try self.getDB()
    let item = try await self.getPerson(pid)
    if pid != item.id {
      Logger.api.warning("person id mismatch: \(pid) != \(item.id)")
      throw ChiiError(message: "这是一个被合并的人物")
    }
    try await db.savePerson(item)
    if item.collectedAt != nil {
      await self.index([item.searchable()])
    }
    try await db.commit()
  }

  func loadPersonDetails(_ personId: Int) async throws {
    let db = try self.getDB()
    await withThrowingTaskGroup(of: Void.self) { group in
      group.addTask {
        let response = try await self.getPersonCasts(personId, limit: 5)
        try await db.savePersonCasts(personId: personId, items: response.data)
      }
      group.addTask {
        let response = try await self.getPersonWorks(personId, limit: 5)
        try await db.savePersonWorks(personId: personId, items: response.data)
      }
    }
    try await db.commit()
  }
}
