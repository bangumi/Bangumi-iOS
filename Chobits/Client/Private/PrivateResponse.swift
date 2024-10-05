//
//  PrivateResponse.swift
//  Chobits
//
//  Created by Chuan Chuan on 2024/10/4.
//

struct NotifyResponse: Codable {
  var data: [Notice]
  var total: Int
}

struct SubjectTopicsResponse: Codable {
  var total: Int
  var data: [Topic]
}
