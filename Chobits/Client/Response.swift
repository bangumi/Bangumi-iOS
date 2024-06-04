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

struct SubjectsResponse: Codable {
  var total: Int
  var limit: Int
  var offset: Int
  var data: [SubjectDTO]
}

struct SubjectCollectionResponse: Codable {
  var total: Int
  var limit: Int
  var offset: Int
  var data: [UserSubjectCollectionDTO]
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
  var data: [EpisodeDTO]
}

struct EpisodeCollectionResponse: Codable {
  var total: Int
  var limit: Int
  var offset: Int
  var data: [EpisodeCollectionDTO]?
}
