import Foundation
import OSLog

enum GroupRepository {
  private static func loadDetailValue<T>(
    label: String,
    work: @Sendable @escaping () async throws -> PagedDTO<T>
  ) -> Task<PagedDTO<T>?, Never> {
    Task { @Sendable in
      do {
        return try await work()
      } catch {
        Logger.api.error("Failed to load \(label): \(error)")
        await MainActor.run {
          Notifier.shared.notify(message: "加载\(label)失败")
        }
        return nil
      }
    }
  }

  static func loadGroup(_ name: String) async throws {
    let db = try await AppContext.shared.getDB()
    let item = try await GroupService.getGroup(name)
    try await db.saveGroup(item)
  }

  static func loadGroupDetails(_ name: String) async throws {
    let db = try await AppContext.shared.getDB()
    let membersTask = loadDetailValue(label: "小组成员") {
      try await GroupService.getGroupMembers(name, role: .member, limit: 10)
    }
    let moderatorsTask = loadDetailValue(label: "小组管理") {
      try await GroupService.getGroupMembers(name, role: .moderator, limit: 10)
    }
    let topicsTask = loadDetailValue(label: "小组话题") {
      try await GroupService.getGroupTopics(name, limit: 10)
    }
    try await db.saveGroupDetails(
      groupName: name,
      recentMembers: await membersTask.value?.data,
      moderators: await moderatorsTask.value?.data,
      recentTopics: await topicsTask.value?.data
    )
  }
}
