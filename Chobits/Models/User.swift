import Foundation
import OSLog
import SwiftData
import SwiftUI

typealias User = UserV1

@Model
final class UserV1 {
  @Attribute(.unique)
  var userId: Int

  var username: String
  var nickname: String
  var avatar: Avatar?
  var group: Int
  var joinedAt: Int
  var sign: String
  var site: String
  var location: String
  var bio: String
  var networkServices: [UserNetworkServiceDTO]
  var homepage: UserHomepageDTO
  var stats: UserStatsDTO?

  var name: String {
    nickname.isEmpty ? "用户\(username)" : nickname
  }

  var groupEnum: UserGroup {
    UserGroup(group)
  }

  var link: String {
    "chii://user/\(username)"
  }

  var slim: SlimUserDTO {
    SlimUserDTO(self)
  }

  init(_ item: UserDTO) {
    self.userId = item.id
    self.username = item.username
    self.nickname = item.nickname
    self.avatar = item.avatar
    self.group = item.group.rawValue
    self.joinedAt = item.joinedAt
    self.sign = item.sign
    self.site = item.site
    self.location = item.location
    self.bio = item.bio
    self.networkServices = item.networkServices
    self.homepage = item.homepage
    self.stats = item.stats
  }

  func update(_ item: UserDTO) {
    if self.username != item.username { self.username = item.username }
    if self.nickname != item.nickname { self.nickname = item.nickname }
    if self.avatar != item.avatar { self.avatar = item.avatar }
    if self.group != item.group.rawValue { self.group = item.group.rawValue }
    if self.joinedAt != item.joinedAt { self.joinedAt = item.joinedAt }
    if self.sign != item.sign { self.sign = item.sign }
    if self.site != item.site { self.site = item.site }
    if self.location != item.location { self.location = item.location }
    if self.bio != item.bio { self.bio = item.bio }
    if self.networkServices != item.networkServices { self.networkServices = item.networkServices }
    if self.homepage != item.homepage { self.homepage = item.homepage }
    if self.stats != item.stats { self.stats = item.stats }
  }
}
