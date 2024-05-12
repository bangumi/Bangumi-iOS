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

  init(_ item: CharacterPersonItem) {
    self.id = item.id
    self.name = item.name
    self.type = 0
    self.career = []
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
}

@Model
final class PersonRelatedSubject {
  @Attribute(.unique)
  var uk: String

  var personId: UInt
  var subjectId: UInt
  var staff: String
  var name: String
  var nameCn: String
  var type: UInt8
  var image: String

  init(
    uk: String, personId: UInt, subjectId: UInt, staff: String, name: String, nameCn: String,
    type: UInt8, image: String
  ) {
    self.uk = uk
    self.personId = personId
    self.subjectId = subjectId
    self.staff = staff
    self.name = name
    self.nameCn = nameCn
    self.type = type
    self.image = image
  }

  init(_ item: PersonSubjectItem, personId: UInt) {
    self.uk = "\(personId)-\(item.id)"
    self.personId = personId
    self.subjectId = item.id
    self.staff = item.staff
    self.name = item.name ?? ""
    self.nameCn = item.nameCn
    self.type = 0 // TODO: add in API
    self.image = item.image ?? ""
  }
}

@Model
final class PersonRelatedCharacter {
  @Attribute(.unique)
  var uk: String

  var personId: UInt
  var characterId: UInt
  var name: String
  var type: UInt8
  var images: Images
  var subjectId: UInt
  var subjectName: String
  var subjectNameCn: String
  var staff: String

  var typeEnum: CharacterType {
    return CharacterType(type)
  }

  init(
    uk: String, personId: UInt, characterId: UInt, name: String, type: UInt8, images: Images,
    subjectId: UInt, subjectName: String, subjectNameCn: String, staff: String
  ) {
    self.uk = uk
    self.personId = personId
    self.characterId = characterId
    self.name = name
    self.type = type
    self.images = images
    self.subjectId = subjectId
    self.subjectName = subjectName
    self.subjectNameCn = subjectNameCn
    self.staff = staff
  }

  init(_ item: PersonCharacterItem, personId: UInt) {
    self.uk = "\(personId)-\(item.id)-\(item.subjectId)"
    self.personId = personId
    self.characterId = item.id
    self.name = item.name
    self.type = item.type.rawValue
    self.images = item.images ?? Images()
    self.subjectId = item.subjectId
    self.subjectName = item.subjectName
    self.subjectNameCn = item.subjectNameCn
    self.staff = item.staff ?? ""
  }
}
