//
//  PrivateDto.swift
//  Chobits
//
//  Created by Chuan Chuan on 2024/10/4.
//

struct Notice: Codable, Identifiable, Equatable {
  var id: UInt
  var postID: UInt
  var sender: User
  var title: String
  var topicID: UInt
  var type: UInt
  var unread: Bool
  var createdAt: UInt

  init() {
    self.id = 0
    self.postID = 0
    self.sender = User()
    self.title = ""
    self.topicID = 0
    self.type = 0
    self.unread = false
    self.createdAt = 0
  }

  static func == (lhs: Notice, rhs: Notice) -> Bool {
    return lhs.id == rhs.id
  }
}
