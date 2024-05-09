//
//  Character.swift
//  Chobits
//
//  Created by Chuan Chuan on 2024/5/8.
//

import Foundation
import SwiftData

@Model
final class Character {
  @Attribute(.unique)
  var id: UInt

  var name: String
  var type: UInt8
  var images: Images
  var summary: String
  var locked: Bool
  var infobox: [InfoboxItem]
  var gender: String?
  var bloodType: UInt8?
  var birthYear: UInt?
  var birthMonth: UInt?
  var birthDay: UInt?
  var stat: Stat

  var typeEnum: CharacterType {
    return CharacterType(type)
  }

  var birthday: String {
    var text = ""
    if let year = birthYear {
      text += "\(year)年"
    }
    if let month = birthMonth {
      text += "\(month)月"
    }
    if let day = birthDay {
      text += "\(day)日"
    }
    return text
  }

  init(
    id: UInt, name: String, type: UInt8, images: Images, summary: String, locked: Bool,
    infobox: [InfoboxItem], gender: String? = nil, bloodType: UInt8? = nil, birthYear: UInt? = nil,
    birthMonth: UInt? = nil, birthDay: UInt? = nil, stat: Stat
  ) {
    self.id = id
    self.name = name
    self.type = type
    self.images = images
    self.summary = summary
    self.locked = locked
    self.infobox = infobox
    self.gender = gender
    self.bloodType = bloodType
    self.birthYear = birthYear
    self.birthMonth = birthMonth
    self.birthDay = birthDay
    self.stat = stat
  }

  init(_ item: CharacterItem) {
    self.id = item.id
    self.name = item.name
    self.type = item.type.rawValue
    self.images = item.images ?? Images()
    self.summary = item.summary
    self.locked = item.locked
    self.infobox = item.infobox
    self.gender = item.gender
    self.bloodType = item.bloodType?.rawValue
    self.birthYear = item.birthYear
    self.birthMonth = item.birthMon
    self.birthDay = item.birthDay
    self.stat = item.stat
  }

  init(_ item: SubjectCharacterItem) {
    self.id = item.id
    self.name = item.name
    self.type = item.type.rawValue
    self.images = item.images ?? Images()
    self.summary = ""
    self.locked = false
    self.infobox = []
    self.gender = nil
    self.bloodType = nil
    self.birthYear = nil
    self.birthMonth = nil
    self.birthDay = nil
    self.stat = Stat()
  }
}
