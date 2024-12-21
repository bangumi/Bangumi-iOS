import Foundation

struct AppInfo: Codable {
  var clientId: String
  var clientSecret: String
  var callbackURL: String
}

struct Auth: Codable {
  var accessToken: String
  var expiresAt: Date
  var refreshToken: String

  init(response: TokenResponse) {
    self.accessToken = response.accessToken
    self.expiresAt = Date().addingTimeInterval(TimeInterval(response.expiresIn))
    self.refreshToken = response.refreshToken
  }

  func isExpired() -> Bool {
    return Date() > expiresAt
  }
}

struct User: Codable, Equatable, Hashable {
  var id: Int
  var username: String
  var nickname: String
  var avatar: Avatar?
  var sign: String

  init() {
    self.id = 0
    self.username = ""
    self.nickname = "匿名"
    self.avatar = nil
    self.sign = ""
  }

  static func == (lhs: User, rhs: User) -> Bool {
    return lhs.id == rhs.id && lhs.username == rhs.username && lhs.nickname == rhs.nickname
  }

  var uid: String {
    if username == "" {
      return String(id)
    } else {
      return username
    }
  }
}

struct BangumiCalendarDTO: Codable {
  var weekday: Weekday
  var items: [CalendarSubjectDTO]
}

struct CalendarSubjectDTO: Codable {
  var id: Int
  var type: SubjectType
  var name: String
  var nameCn: String
  var summary: String
  var images: SubjectImages?
}

struct SubjectDTOV0: Codable {
  var id: Int
  var type: SubjectType
  var name: String
  var nameCn: String
  var summary: String
  var series: Bool
  var nsfw: Bool
  var locked: Bool
  var date: String?
  var platform: String?
  var images: SubjectImages
  var volumes: Int
  // var infobox: [String: String]
  var eps: Int
  var rating: SubjectRatingV0
  var collection: SubjectCollection
  var metaTags: [String]
  var tags: [Tag]
}

struct SubjectRatingV0: Codable {
  var count: [String: Int]
  var total: Int
  var score: Float
  var rank: Int

}
