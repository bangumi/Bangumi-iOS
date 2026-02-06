import Foundation
import OSLog
import SwiftData
import SwiftUI

extension Chii {
  func loadUser(_ username: String) async throws -> UserDTO {
    let db = try self.getDB()
    let item = try await self.getUser(username)
    let created = try await db.saveUser(item)
    if created {
      try await db.commitImmediately()
    } else {
      await db.commit()
    }
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
      await db.commit()
    }
  }

  func loadTrendingSubjects() async throws {
    var tasks: [Task<Void, any Error>] = []
    for type in SubjectType.allTypes {
      tasks.append(
        Task {
          let db = try self.getDB()
          let response = try await self.getTrendingSubjects(type: type)
          try await db.saveTrendingSubjects(type: type.rawValue, items: response.data)
          await db.commit()
        })
    }
    for task in tasks {
      try await task.value
    }
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

    let created = try await db.saveSubject(item)
    if created {
      try await db.commitImmediately()
    } else {
      await db.commit()
    }
    if item.interest != nil {
      await self.index([item.searchable()])
    }
    return item
  }

  func loadSubjectDetails(_ subjectId: Int, offprints: Bool, social: Bool) async throws {
    var tasks: [Task<Void, any Error>] = []

    tasks.append(
      Task {
        let db = try self.getDB()
        let val = try await self.getSubjectCharacters(subjectId, limit: 12)
        try await db.saveSubjectCharacters(subjectId: subjectId, items: val.data)
        await db.commit()
      })

    tasks.append(
      Task {
        let db = try self.getDB()
        let val = try await self.getSubjectRelations(subjectId, limit: 10)
        try await db.saveSubjectRelations(subjectId: subjectId, items: val.data)
        await db.commit()
      })

    tasks.append(
      Task {
        let db = try self.getDB()
        let val = try await self.getSubjectRecs(subjectId, limit: 10)
        try await db.saveSubjectRecs(subjectId: subjectId, items: val.data)
        await db.commit()
      })

    tasks.append(
      Task {
        let db = try self.getDB()
        let val = try await self.getSubjectIndexes(subjectId: subjectId, limit: 5)
        try await db.saveSubjectIndexes(subjectId: subjectId, items: val.data)
        await db.commit()
      })

    if offprints {
      tasks.append(
        Task {
          let db = try self.getDB()
          let val = try await self.getSubjectRelations(subjectId, offprint: true, limit: 100)
          try await db.saveSubjectOffprints(subjectId: subjectId, items: val.data)
          await db.commit()
        })
    }

    if social {
      tasks.append(
        Task {
          let collectsModeDefaults = UserDefaults.standard.string(
            forKey: "subjectCollectsFilterMode")
          let collectsMode = FilterMode(collectsModeDefaults)
          let db = try self.getDB()
          let val = try await self.getSubjectCollects(subjectId, mode: collectsMode, limit: 10)
          try await db.saveSubjectCollects(subjectId: subjectId, items: val.data)
          await db.commit()
        })

      tasks.append(
        Task {
          let db = try self.getDB()
          let val = try await self.getSubjectReviews(subjectId, limit: 5)
          try await db.saveSubjectReviews(subjectId: subjectId, items: val.data)
          await db.commit()
        })

      tasks.append(
        Task {
          let db = try self.getDB()
          let val = try await self.getSubjectTopics(subjectId, limit: 5)
          try await db.saveSubjectTopics(subjectId: subjectId, items: val.data)
          await db.commit()
        })

      tasks.append(
        Task {
          let db = try self.getDB()
          let val = try await self.getSubjectComments(subjectId, limit: 10)
          try await db.saveSubjectComments(subjectId: subjectId, items: val.data)
          await db.commit()
        })
    }

    for task in tasks {
      try await task.value
    }
  }

  func loadSubjectPositions(_ subjectId: Int) async throws {
    let db = try self.getDB()
    let limit: Int = 100
    var offset: Int = 0
    var items: [SubjectPositionDTO] = []
    while true {
      let response = try await self.getSubjectStaffPositions(
        subjectId, limit: limit, offset: offset)
      if response.data.isEmpty {
        break
      }
      items.append(contentsOf: response.data)
      offset += limit
      if offset > response.total {
        break
      }
    }
    try await db.saveSubjectPositions(subjectId: subjectId, items: items)
    await db.commit()
  }

  func loadEpisodes(_ subjectId: Int) async throws {
    let db = try self.getDB()
    var offset: Int = 0
    let limit: Int = 1000
    var total: Int = 0
    var items: [EpisodeDTO] = []
    var episodeIds = Set<Int>()
    while true {
      let response = try await self.getSubjectEpisodes(
        subjectId, limit: limit, offset: offset)
      total = response.total
      if response.data.isEmpty {
        break
      }
      for item in response.data {
        items.append(item)
        episodeIds.insert(item.id)
      }
      offset += limit
      if offset > total {
        break
      }
    }
    for item in items {
      try await db.saveEpisode(item)
    }
    try await db.deleteEpisodesNotIn(subjectId: subjectId, episodeIds: episodeIds)
    await db.commit()
  }

  func loadEpisode(_ episodeId: Int) async throws {
    let db = try self.getDB()
    let item = try await self.getEpisode(episodeId)
    let created = try await db.saveEpisode(item)
    if created {
      try await db.commitImmediately()
    } else {
      await db.commit()
    }
  }

  func deleteEpisode(_ episodeId: Int) async throws {
    let db = try self.getDB()
    try await db.deleteEpisode(episodeId)
    await db.commit()
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
    let created = try await db.saveCharacter(item)
    if created {
      try await db.commitImmediately()
    } else {
      await db.commit()
    }
    if item.collectedAt != nil {
      await self.index([item.searchable()])
    }
  }

  func loadCharacterDetails(_ characterId: Int) async throws {
    var tasks: [Task<Void, any Error>] = []

    tasks.append(
      Task {
        let db = try self.getDB()
        let val = try await self.getCharacterCasts(characterId, limit: 5)
        try await db.saveCharacterCasts(characterId: characterId, items: val.data)
        await db.commit()
      })

    tasks.append(
      Task {
        let db = try self.getDB()
        let val = try await self.getCharacterIndexes(characterId: characterId, limit: 5)
        try await db.saveCharacterIndexes(characterId: characterId, items: val.data)
        await db.commit()
      })

    for task in tasks {
      try await task.value
    }
  }

  func loadPerson(_ pid: Int) async throws {
    let db = try self.getDB()
    let item = try await self.getPerson(pid)
    if pid != item.id {
      Logger.api.warning("person id mismatch: \(pid) != \(item.id)")
      throw ChiiError(message: "这是一个被合并的人物")
    }
    let created = try await db.savePerson(item)
    if created {
      try await db.commitImmediately()
    } else {
      await db.commit()
    }
    if item.collectedAt != nil {
      await self.index([item.searchable()])
    }
  }

  func loadPersonDetails(_ personId: Int) async throws {
    var tasks: [Task<Void, any Error>] = []

    tasks.append(
      Task {
        let db = try self.getDB()
        let val = try await self.getPersonCasts(personId, limit: 5)
        try await db.savePersonCasts(personId: personId, items: val.data)
        await db.commit()
      })

    tasks.append(
      Task {
        let db = try self.getDB()
        let val = try await self.getPersonWorks(personId, limit: 5)
        try await db.savePersonWorks(personId: personId, items: val.data)
        await db.commit()
      })

    tasks.append(
      Task {
        let db = try self.getDB()
        let val = try await self.getPersonIndexes(personId: personId, limit: 5)
        try await db.savePersonIndexes(personId: personId, items: val.data)
        await db.commit()
      })

    for task in tasks {
      try await task.value
    }
  }
}

extension Chii {
  func loadGroup(_ name: String) async throws {
    let db = try self.getDB()
    let item = try await self.getGroup(name)
    let created = try await db.saveGroup(item)
    if created {
      try await db.commitImmediately()
    } else {
      await db.commit()
    }
  }

  func loadGroupDetails(_ name: String) async throws {
    var tasks: [Task<Void, any Error>] = []

    tasks.append(
      Task {
        let db = try self.getDB()
        let val = try await self.getGroupMembers(name, role: .member, limit: 10)
        try await db.saveGroupRecentMembers(groupName: name, items: val.data)
        await db.commit()
      })

    tasks.append(
      Task {
        let db = try self.getDB()
        let val = try await self.getGroupMembers(name, role: .moderator, limit: 10)
        try await db.saveGroupModerators(groupName: name, items: val.data)
        await db.commit()
      })

    tasks.append(
      Task {
        let db = try self.getDB()
        let val = try await self.getGroupTopics(name, limit: 10)
        try await db.saveGroupRecentTopics(groupName: name, items: val.data)
        await db.commit()
      })

    for task in tasks {
      try await task.value
    }
  }
}
