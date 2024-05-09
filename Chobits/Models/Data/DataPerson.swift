//
//  Person.swift
//  Chobits
//
//  Created by Chuan Chuan on 2024/5/8.
//

import Foundation
import SwiftData

@Model
final class Person {
  @Attribute(.unique)
  var id: UInt
  var name: String
  var type: UInt8
  var career: [String]
  var images: Images
  var summary: String
  var locked: Bool
  var lastModified: Date
  var infobox: [InfoboxItem]
  var gender: String?
  var bloodType: UInt8?
  var birthYear: UInt?
  var birthMonth: UInt?
  var birthDay: UInt?
  var stat: Stat

  var typeEnum: PersonType {
    return PersonType(type)
  }

  init(
    id: UInt, name: String, type: UInt8, career: [String], images: Images, summary: String,
    locked: Bool, lastModified: Date, infobox: [InfoboxItem], gender: String? = nil,
    bloodType: UInt8? = nil, birthYear: UInt? = nil, birthMonth: UInt? = nil, birthDay: UInt? = nil,
    stat: Stat
  ) {
    self.id = id
    self.name = name
    self.type = type
    self.career = career
    self.images = images
    self.summary = summary
    self.locked = locked
    self.lastModified = lastModified
    self.infobox = infobox
    self.gender = gender
    self.bloodType = bloodType
    self.birthYear = birthYear
    self.birthMonth = birthMonth
    self.birthDay = birthDay
    self.stat = stat
  }

  init(_ item: PersonItem) {
    self.id = item.id
    self.name = item.name
    self.type = item.type.rawValue
    self.career = item.career.map { $0.label }
    self.images = item.images ?? Images()
    self.summary = item.summary
    self.locked = item.locked
    self.lastModified = safeParseRFC3339Date(str: item.lastModified)
    self.infobox = item.infobox
    self.gender = item.gender
    self.bloodType = item.bloodType?.rawValue
    self.birthYear = item.birthYear
    self.birthMonth = item.birthMonth
    self.birthDay = item.birthDay
    self.stat = item.stat
  }

  init(_ item: SubjectPersonItem) {
    self.id = item.id
    self.name = item.name
    self.type = item.type.rawValue
    self.career = item.career.map { $0.label }
    self.images = item.images ?? Images()
    self.summary = ""
    self.locked = false
    self.lastModified = Date()
    self.infobox = []
    self.gender = nil
    self.bloodType = nil
    self.birthYear = nil
    self.birthMonth = nil
    self.birthDay = nil
    self.stat = Stat()
  }

  init(_ item: SubjectCharacterActorItem) {
    self.id = item.id
    self.name = item.name
    self.type = item.type.rawValue
    self.career = item.career.map { $0.label }
    self.images = item.images ?? Images()
    self.summary = item.shortSummary
    self.locked = item.locked
    self.lastModified = Date()
    self.infobox = []
    self.gender = nil
    self.bloodType = nil
    self.birthYear = nil
    self.birthMonth = nil
    self.birthDay = nil
    self.stat = Stat()
  }
}
