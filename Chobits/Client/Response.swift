//
//  Response.swift
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
  var total: Int
  var limit: Int
  var offset: Int
  var data: [UserSubjectCollection]
}

struct SubjectSearchResponse: Codable {
  var total: Int
  var limit: Int
  var offset: Int
  var data: [SearchSubject]
}

struct EpisodeResponse: Codable {
  var total: Int
  var limit: Int
  var offset: Int
  var data: [EpisodeItem]
}

struct EpisodeCollectionResponse: Codable {
  var total: Int
  var limit: Int
  var offset: Int
  var data: [EpisodeCollectionItem]
}
