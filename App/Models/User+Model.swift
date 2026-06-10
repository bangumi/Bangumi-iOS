import Foundation
import SwiftData

typealias User = BangumiSchemaV2.UserV1

extension User {
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
