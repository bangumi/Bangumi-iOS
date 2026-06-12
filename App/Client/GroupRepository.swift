import Foundation
import OSLog

enum GroupRepository {
  private static func saveAndCommit(db: DatabaseOperator, created: Bool) async throws {
    if created {
      try await db.commitImmediately()
    } else {
      await db.commit()
    }
  }

  private static func loadDetail(
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

  static func loadGroup(_ name: String) async throws {
    let db = try await AppContext.shared.getDB()
    let item = try await GroupService.getGroup(name)
    let created = try await db.saveGroup(item)
    try await saveAndCommit(db: db, created: created)
  }

  static func loadGroupDetails(_ name: String) async throws {
    let db = try await AppContext.shared.getDB()
    let tasks: [Task<Void, Never>] = [
      loadDetail(label: "小组成员") {
        let response = try await GroupService.getGroupMembers(name, role: .member, limit: 10)
        try await db.saveGroupRecentMembers(groupName: name, items: response.data)
        await db.commit()
      },
      loadDetail(label: "小组管理") {
        let response = try await GroupService.getGroupMembers(name, role: .moderator, limit: 10)
        try await db.saveGroupModerators(groupName: name, items: response.data)
        await db.commit()
      },
      loadDetail(label: "小组话题") {
        let response = try await GroupService.getGroupTopics(name, limit: 10)
        try await db.saveGroupRecentTopics(groupName: name, items: response.data)
        await db.commit()
      },
    ]
    for task in tasks {
      await task.value
    }
  }
}
