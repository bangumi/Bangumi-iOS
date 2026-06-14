import Foundation

enum UserRepository {
  static func loadUser(_ username: String) async throws -> UserDTO {
    let db = try await AppContext.shared.getDB()
    let item = try await UserService.getUser(username)
    try await db.saveUser(item)
    return item
  }
}
