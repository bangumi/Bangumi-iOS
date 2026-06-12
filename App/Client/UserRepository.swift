import Foundation

enum UserRepository {
  private static func saveAndCommit(db: DatabaseOperator, created: Bool) async throws {
    if created {
      try await db.commitImmediately()
    } else {
      await db.commit()
    }
  }

  static func loadUser(_ username: String) async throws -> UserDTO {
    let db = try await AppContext.shared.getDB()
    let item = try await UserService.getUser(username)
    let created = try await db.saveUser(item)
    try await saveAndCommit(db: db, created: created)
    return item
  }
}
