//
//  PrivateResponse.swift
//  Chobits
//
//  Created by Chuan Chuan on 2024/10/4.
//

struct NotifyResponse: Codable {
  var total: Int
  var data: [Notice]
}

struct SubjectTopicsResponse: Codable {
  var total: Int
  var data: [Topic]
}

struct SubjectInterestCommentsResponse: Codable {
  var total: Int
  var list: [SubjectInterestComment]
}
