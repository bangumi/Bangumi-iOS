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
