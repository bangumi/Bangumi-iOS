import Foundation
import SwiftData

typealias User = BangumiSchemaV3.UserV2

extension User {
  var networkServices: [UserNetworkServiceDTO] {
    get { PersistedJSON.decode([UserNetworkServiceDTO].self, from: networkServicesData) ?? [] }
    set { networkServicesData = PersistedJSON.encode(newValue) ?? networkServicesData }
  }

  var homepage: UserHomepageDTO {
    get {
      PersistedJSON.decode(UserHomepageDTO.self, from: homepageData)
        ?? UserHomepageDTO(left: [], right: [])
    }
    set { homepageData = PersistedJSON.encode(newValue) ?? homepageData }
  }

  var stats: UserStatsDTO? {
    get { PersistedJSON.decode(UserStatsDTO.self, from: statsData) }
    set { statsData = newValue.flatMap(PersistedJSON.encode) }
  }

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
