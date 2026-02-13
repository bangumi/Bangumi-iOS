import Foundation
import OSLog
import SwiftData
import SwiftUI

extension Chii {
  private func saveAndCommit(db: DatabaseOperator, created: Bool) async throws {
    if created {
      try await db.commitImmediately()
    } else {
      await db.commit()
    }
  }

  private func loadDetail(
    label: String,
    work: @Sendable @escaping () async throws -> Void
  ) -> Task<Void, Never> {
    Task { @Sendable in
      do {
        try await work()
      } catch {
        Logger.api.error("Failed to load \(label): \(error)")
        await MainActor.run {
          Notifier.shared.notify(message: "加载\(label)失败")
        }
      }
    }
  }

  func loadUser(_ username: String) async throws -> UserDTO {
    let db = try self.getDB()
    let item = try await self.getUser(username)
    let created = try await db.saveUser(item)
    try await self.saveAndCommit(db: db, created: created)
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
    await db.commit()
  }

  func loadTrendingSubjects() async throws {
    var tasks: [Task<Void, Error>] = []
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
    try await self.saveAndCommit(db: db, created: created)
    if item.interest != nil {
      await self.index([item.searchable()])
    }
    return item
  }

  func loadSubjectDetails(_ subjectId: Int, offprints: Bool, social: Bool) async throws {
    let db = try self.getDB()
    let collectsMode: FilterMode? = {
      guard social else { return nil }
      let collectsModeDefaults = UserDefaults.standard.string(
        forKey: "subjectCollectsFilterMode")
      return FilterMode(collectsModeDefaults)
    }()

    var tasks: [Task<Void, Never>] = []

    func addTask<T>(
      label: String,
      work: @Sendable @escaping () async throws -> PagedDTO<T>,
      save: @Sendable @escaping (PagedDTO<T>) async throws -> Void
    ) {
      tasks.append(
        Task { @Sendable in
          do {
            let value = try await work()
            try await save(value)
            await db.commit()
          } catch {
            Logger.api.error("Failed to load subject detail (\(label)): \(error)")
            await MainActor.run {
              Notifier.shared.notify(message: "加载\(label)失败")
            }
          }
        })
    }

    addTask(
      label: "条目角色",
      work: { try await self.getSubjectCharacters(subjectId, limit: 12) },
      save: { value in
        try await db.saveSubjectCharacters(subjectId: subjectId, items: value.data)
      }
    )
    addTask(
      label: "关联条目",
      work: { try await self.getSubjectRelations(subjectId, limit: 10) },
      save: { value in
        try await db.saveSubjectRelations(subjectId: subjectId, items: value.data)
      }
    )
    addTask(
      label: "推荐条目",
      work: { try await self.getSubjectRecs(subjectId, limit: 10) },
      save: { value in
        try await db.saveSubjectRecs(subjectId: subjectId, items: value.data)
      }
    )
    addTask(
      label: "条目目录",
      work: { try await self.getSubjectIndexes(subjectId: subjectId, limit: 5) },
      save: { value in
        try await db.saveSubjectIndexes(subjectId: subjectId, items: value.data)
      }
    )

    if offprints {
      addTask(
        label: "条目衍生",
        work: { try await self.getSubjectRelations(subjectId, offprint: true, limit: 100) },
        save: { value in
          try await db.saveSubjectOffprints(subjectId: subjectId, items: value.data)
        }
      )
    }

    if let collectsMode {
      addTask(
        label: "收藏用户",
        work: { try await self.getSubjectCollects(subjectId, mode: collectsMode, limit: 10) },
        save: { value in
          try await db.saveSubjectCollects(subjectId: subjectId, items: value.data)
        }
      )
      addTask(
        label: "评论",
        work: { try await self.getSubjectReviews(subjectId, limit: 5) },
        save: { value in
          try await db.saveSubjectReviews(subjectId: subjectId, items: value.data)
        }
      )
      addTask(
        label: "讨论",
        work: { try await self.getSubjectTopics(subjectId, limit: 5) },
        save: { value in
          try await db.saveSubjectTopics(subjectId: subjectId, items: value.data)
        }
      )
      addTask(
        label: "吐槽",
        work: { try await self.getSubjectComments(subjectId, limit: 10) },
        save: { value in
          try await db.saveSubjectComments(subjectId: subjectId, items: value.data)
        }
      )
    }

    for task in tasks {
      await task.value
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
      if offset >= response.total {
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
      if offset >= total {
        break
      }
    }
    try await db.saveEpisodes(subjectId: subjectId, items: items)
    try await db.deleteEpisodesNotIn(subjectId: subjectId, episodeIds: episodeIds)
    await db.commit()
  }

  func loadEpisode(_ episodeId: Int) async throws {
    let db = try self.getDB()
    let item = try await self.getEpisode(episodeId)
    let created = try await db.saveEpisode(item)
    try await self.saveAndCommit(db: db, created: created)
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
    try await self.saveAndCommit(db: db, created: created)
    if item.collectedAt != nil {
      await self.index([item.searchable()])
    }
  }

  func loadCharacterDetails(_ characterId: Int) async throws {
    let db = try self.getDB()
    let tasks: [Task<Void, Never>] = [
      loadDetail(label: "角色参演") {
        let response = try await self.getCharacterCasts(characterId, limit: 5)
        try await db.saveCharacterCasts(characterId: characterId, items: response.data)
        await db.commit()
      },
      loadDetail(label: "角色目录") {
        let response = try await self.getCharacterIndexes(characterId: characterId, limit: 5)
        try await db.saveCharacterIndexes(characterId: characterId, items: response.data)
        await db.commit()
      },
    ]
    for task in tasks {
      await task.value
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
    try await self.saveAndCommit(db: db, created: created)
    if item.collectedAt != nil {
      await self.index([item.searchable()])
    }
  }

  func loadPersonDetails(_ personId: Int) async throws {
    let db = try self.getDB()
    let tasks: [Task<Void, Never>] = [
      loadDetail(label: "人物参演") {
        let response = try await self.getPersonCasts(personId, limit: 5)
        try await db.savePersonCasts(personId: personId, items: response.data)
        await db.commit()
      },
      loadDetail(label: "人物作品") {
        let response = try await self.getPersonWorks(personId, limit: 5)
        try await db.savePersonWorks(personId: personId, items: response.data)
        await db.commit()
      },
      loadDetail(label: "人物目录") {
        let response = try await self.getPersonIndexes(personId: personId, limit: 5)
        try await db.savePersonIndexes(personId: personId, items: response.data)
        await db.commit()
      },
    ]
    for task in tasks {
      await task.value
    }
  }
}

extension Chii {
  func loadGroup(_ name: String) async throws {
    let db = try self.getDB()
    let item = try await self.getGroup(name)
    let created = try await db.saveGroup(item)
    try await self.saveAndCommit(db: db, created: created)
  }

  func loadGroupDetails(_ name: String) async throws {
    let db = try self.getDB()
    let tasks: [Task<Void, Never>] = [
      loadDetail(label: "小组成员") {
        let response = try await self.getGroupMembers(name, role: .member, limit: 10)
        try await db.saveGroupRecentMembers(groupName: name, items: response.data)
        await db.commit()
      },
      loadDetail(label: "小组管理") {
        let response = try await self.getGroupMembers(name, role: .moderator, limit: 10)
        try await db.saveGroupModerators(groupName: name, items: response.data)
        await db.commit()
      },
      loadDetail(label: "小组话题") {
        let response = try await self.getGroupTopics(name, limit: 10)
        try await db.saveGroupRecentTopics(groupName: name, items: response.data)
        await db.commit()
      },
    ]
    for task in tasks {
      await task.value
    }
  }
}
