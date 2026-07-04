import Foundation

enum ProfilePrivacyValue: String, Codable, CaseIterable, Identifiable, Hashable, Sendable {
  case all
  case friends
  case none

  var id: Self {
    self
  }

  static var binaryValues: [Self] {
    [.all, .none]
  }
}

struct ProfilePrivacySettingsDTO: Codable, Equatable, Sendable {
  var privateMessage: ProfilePrivacyValue
  var timelineReply: ProfilePrivacyValue
  var timelineCollectReply: ProfilePrivacyValue
  var follow: ProfilePrivacyValue
  var mentionNotification: ProfilePrivacyValue
  var commentNotification: ProfilePrivacyValue
  var friendNotification: ProfilePrivacyValue

  init(
    privateMessage: ProfilePrivacyValue = .all,
    timelineReply: ProfilePrivacyValue = .all,
    timelineCollectReply: ProfilePrivacyValue = .friends,
    follow: ProfilePrivacyValue = .all,
    mentionNotification: ProfilePrivacyValue = .all,
    commentNotification: ProfilePrivacyValue = .all,
    friendNotification: ProfilePrivacyValue = .all
  ) {
    self.privateMessage = privateMessage
    self.timelineReply = timelineReply
    self.timelineCollectReply = timelineCollectReply
    self.follow = follow
    self.mentionNotification = mentionNotification
    self.commentNotification = commentNotification
    self.friendNotification = friendNotification
  }
}

struct ProfilePrivacyPreferencesDTO: Codable, Equatable, Sendable {
  var showNsfwSubject: Bool
  var canSetNsfwSubject: Bool
  var allowNsfw: Bool
}

struct ProfilePrivacyDTO: Codable, Equatable, Sendable {
  var settings: ProfilePrivacySettingsDTO
  var preferences: ProfilePrivacyPreferencesDTO
}

enum PrivacyService {
  static func getProfilePrivacy() async throws -> ProfilePrivacyDTO {
    let url = BangumiURL.next(path: "p1/privacy")
    let data = try await APIClient.shared.request(url: url, method: "GET", auth: .required)
    let resp: ProfilePrivacyDTO = try await APIClient.shared.decodeResponse(data)
    return resp
  }

  static func updateProfilePrivacy(
    settings: ProfilePrivacySettingsDTO,
    showNsfwSubject: Bool?
  ) async throws -> ProfilePrivacyDTO {
    let url = BangumiURL.next(path: "p1/privacy")
    var body: [String: Any] = [
      "settings": [
        "privateMessage": settings.privateMessage.rawValue,
        "timelineReply": settings.timelineReply.rawValue,
        "timelineCollectReply": settings.timelineCollectReply.rawValue,
        "follow": settings.follow.rawValue,
        "mentionNotification": settings.mentionNotification.rawValue,
        "commentNotification": settings.commentNotification.rawValue,
        "friendNotification": settings.friendNotification.rawValue,
      ]
    ]
    if let showNsfwSubject {
      body["preferences"] = [
        "showNsfwSubject": showNsfwSubject
      ]
    }

    let data = try await APIClient.shared.request(
      url: url,
      method: "PATCH",
      body: body,
      auth: .required
    )
    let resp: ProfilePrivacyDTO = try await APIClient.shared.decodeResponse(data)
    return resp
  }
}
