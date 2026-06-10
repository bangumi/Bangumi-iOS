import Foundation
import SwiftData

typealias ChiiGroup = BangumiSchemaV2.GroupV2

extension ChiiGroup {
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
