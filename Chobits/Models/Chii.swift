//
//  Chii.swift
//  Chobits
//
//  Created by Chuan Chuan on 2024/4/21.
//

import Foundation

struct ResponseDetailedError: Codable, CustomStringConvertible {
  var path: String
  var error: String?
  var method: String?
  var queryString: String?

  var description: String {
    var desc = "path: \(path)"
    if let error = error {
      desc += ", error: \(error)"
    }
    if let method = method {
      desc += ", method: \(method)"
    }
    if let queryString = queryString {
      desc += ", queryString: \(queryString)"
    }
    return desc
  }
}

enum ResponseErrorDetails: Codable, CustomStringConvertible {
  case string(String)
  case detail(ResponseDetailedError)

  init(from decoder: Decoder) throws {
    let container = try decoder.singleValueContainer()
    if let string = try? container.decode(String.self) {
      self = .string(string)
      return
    }
    if let path = try? container.decode(ResponseDetailedError.self) {
      self = .detail(path)
      return
    }
    throw DecodingError.typeMismatch(ResponseErrorDetails.self, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Wrong type for ResponseErrorDetails"))
  }

  func encode(to encoder: Encoder) throws {
    var container = encoder.singleValueContainer()
    switch self {
    case .string(let string):
      try container.encode(string)
    case .detail(let path):
      try container.encode(path)
    }
  }

  var description: String {
    switch self {
    case .string(let string):
      return string
    case .detail(let path):
      return path.description
    }
  }
}

struct ResponseError: Codable, CustomStringConvertible {
  var title: String
  var description: String
  var details: ResponseErrorDetails

  var display: String {
    return "API ERROR: \(title): \(description)\n\n\(details)"
  }
}

enum ChiiError: Error, CustomStringConvertible {
  case badRequest(ResponseError)
  case notAuthorized(ResponseError)
  case notFound(ResponseError)
  case generic(String)

  init(message: String) {
    self = .generic(message)
  }

  init(code: Int, response: ResponseError) {
    switch code {
    case 400:
      self = .badRequest(response)
    case 401, 403:
      self = .notAuthorized(response)
    case 404:
      self = .notFound(response)
    default:
      self = .generic(response.description)
    }
  }

  var description: String {
    switch self {
    case .badRequest(let error):
      return "Bad Request!\n\(error.display)"
    case .notAuthorized(let error):
      return "Unauthorized!\n\(error.display)"
    case .notFound(let error):
      return "Not Found!\n\(error.display)"
    case .generic(let message):
      return message
    }
  }
}

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

struct Profile: Codable {
  var id: UInt
  var username: String
  var nickname: String
  var userGroup: UserGroup
  var avatar: Avatar
  var sign: String
}

struct SlimSubject: Codable, Identifiable {
  var id: UInt
  var type: SubjectType
  var name: String
  var nameCn: String
  var shortSummary: String
  var date: String?
  var images: SubjectImages
  var volumes: UInt
  var eps: UInt
  var collectionTotal: UInt
  var score: Float
  var tags: [Tag]
}

struct SearchSubject: Codable, Identifiable, Hashable {
  var id: UInt
  var type: SubjectType?
  var date: String
  var image: String
  var summary: String
  var name: String
  var nameCn: String
  var tags: [Tag]
  var score: Float
  var rank: UInt

  func hash(into hasher: inout Hasher) {
    hasher.combine(id)
  }

  static func ==(lhs: Self, rhs: Self) -> Bool {
    return lhs.id == rhs.id
  }
}

struct SmallSubject: Codable, Identifiable, Hashable {
  var id: UInt
  var url: String
  var type: SubjectType
  var name: String
  var nameCn: String
  var summary: String
  var airDate: String
  var airWeekday: UInt
  var images: SubjectImages?
  var rating: SmallRating?
  var rank: UInt?
  var collection: SubjectCollection?

  func hash(into hasher: inout Hasher) {
    hasher.combine(id)
  }

  static func ==(lhs: Self, rhs: Self) -> Bool {
    return lhs.id == rhs.id
  }
}

struct SubjectPerson: Codable, Identifiable {
  var id: UInt
  var name: String
  var type: PersonType
  var career: PersonCareer
  var images: Images?
  var relation: String
}

struct Actor: Codable, Identifiable {
  var id: UInt
  var name: String
  var type: PersonType
  var career: PersonCareer
  var images: Images?
  var shortSummary: String
  var locked: Bool
}

struct SubjectCharactor: Codable, Identifiable {
  var id: UInt
  var name: String
  var type: CharacterType
  var images: Images?
  var relation: String
  var actors: [Actor]?
}

struct SubjectRelation: Codable, Identifiable {
  var id: UInt
  var type: SubjectType
  var name: String
  var nameCn: String
  var images: SubjectImages?
  var relation: String
}

struct Episode: Codable, Identifiable {
  var id: UInt
  var type: EpisodeType
  var name: String
  var nameCn: String
  var sort: Float
  var ep: Float?
  var airdate: String
  var comment: UInt
  var duration: String
  var desc: String
  var disc: String
  var durationSeconds: UInt?
}

struct EpisodeDetail: Codable, Identifiable {
  var id: UInt
  var type: EpisodeType
  var name: String
  var nameCn: String
  var sort: Float
  var ep: Float?
  var airdate: String
  var comment: UInt
  var duration: String
  var desc: String
  var disc: String
  var subjectId: UInt
}
