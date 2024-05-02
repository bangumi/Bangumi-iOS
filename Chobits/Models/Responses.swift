//
//  Responses.swift
//  Chobits
//
//  Created by Chuan Chuan on 2024/4/26.
//

struct TokenResponse: Codable {
  var accessToken: String
  var expiresIn: UInt
  var tokenType: String
  var refreshToken: String
}

struct SubjectCollectionResponse: Codable {
  var total: UInt
  var limit: UInt
  var offset: UInt
  var data: [UserSubjectCollection]
}

struct SubjectSearchResponse: Codable {
  var total: UInt
  var limit: UInt
  var offset: UInt
  var data: [SearchSubject]
}

struct EpisodeResponse: Codable {
  var total: UInt
  var limit: UInt
  var offset: UInt
  var data: [Episode]
}

struct EpisodeCollectionResponse: Codable {
  var total: UInt
  var limit: UInt
  var offset: UInt
  var data: [EpisodeCollection]
}
