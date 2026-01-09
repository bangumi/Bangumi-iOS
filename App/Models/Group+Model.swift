import Foundation
import OSLog
import SwiftData
import SwiftUI

typealias Group = GroupV2

@Model
final class GroupV2: Linkable {
  @Attribute(.unique)
  var groupId: Int

  var name: String
  var nsfw: Bool
  var title: String
  var icon: Avatar?
  var creator: SlimUserDTO?
  var creatorID: Int
  var desc: String
  var cat: Int
  var accessible: Bool
  var members: Int
  var posts: Int
  var topics: Int
  var createdAt: Int

  /// membership
  var role: Int = -1
  var joinedAt: Int = 0

  /// details
  var moderators: [GroupMemberDTO] = []
  var recentMembers: [GroupMemberDTO] = []
  var recentTopics: [TopicDTO] = []

  var link: String {
    return "chii://group/\(name)"
  }

  var slim: SlimGroupDTO {
    SlimGroupDTO(
      id: groupId,
      name: name,
      nsfw: nsfw,
      title: title,
      icon: icon,
      creatorID: creatorID,
      members: members,
      createdAt: createdAt,
      accessible: accessible
    )
  }

  var memberRole: GroupMemberRole {
    return GroupMemberRole(rawValue: role) ?? .guest
  }

  var canCreateTopic: Bool {
    if accessible {
      return true
    }
    switch memberRole {
    case .member, .moderator, .creator:
      return true
    default:
      return false
    }
  }

  init(_ item: GroupDTO) {
    self.groupId = item.id
    self.name = item.name
    self.nsfw = item.nsfw
    self.title = item.title
    self.icon = item.icon
    self.creator = item.creator
    self.creatorID = item.creatorID
    self.desc = item.description
    self.cat = item.cat
    self.accessible = item.accessible
    self.members = item.members
    self.posts = item.posts
    self.topics = item.topics
    self.createdAt = item.createdAt
    self.role = item.membership?.role?.rawValue ?? -1
    self.joinedAt = item.membership?.joinedAt ?? 0
  }

  func update(_ item: GroupDTO) {
    if self.name != item.name { self.name = item.name }
    if self.nsfw != item.nsfw { self.nsfw = item.nsfw }
    if self.title != item.title { self.title = item.title }
    if self.icon != item.icon { self.icon = item.icon }
    if self.creator != item.creator { self.creator = item.creator }
    if self.creatorID != item.creatorID { self.creatorID = item.creatorID }
    if self.desc != item.description { self.desc = item.description }
    if self.cat != item.cat { self.cat = item.cat }
    if self.accessible != item.accessible { self.accessible = item.accessible }
    if self.members != item.members { self.members = item.members }
    if self.posts != item.posts { self.posts = item.posts }
    if self.topics != item.topics { self.topics = item.topics }
    if self.createdAt != item.createdAt { self.createdAt = item.createdAt }
    let joinedAt = item.membership?.joinedAt ?? 0
    if self.joinedAt != joinedAt { self.joinedAt = joinedAt }
    let role = item.membership?.role?.rawValue ?? -1
    if self.role != role { self.role = role }
  }
}
