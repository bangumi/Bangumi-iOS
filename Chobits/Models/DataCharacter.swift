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
  var characterId: UInt

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
    characterId: UInt, name: String, type: UInt8, images: Images, summary: String, locked: Bool,
    infobox: [InfoboxItem], gender: String? = nil, bloodType: UInt8? = nil, birthYear: UInt? = nil,
    birthMonth: UInt? = nil, birthDay: UInt? = nil, stat: Stat
  ) {
    self.characterId = characterId
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

  init(_ item: CharacterDTO) {
    self.characterId = item.id
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

  init(_ item: SubjectCharacterDTO) {
    self.characterId = item.id
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

  init(_ item: PersonCharacterDTO) {
    self.characterId = item.id
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

@Model
final class CharacterRelatedSubject {
  @Attribute(.unique)
  var uk: String

  var characterId: UInt
  var subjectId: UInt
  var staff: String
  var name: String
  var nameCn: String
  var type: UInt8
  var image: String

  var typeEnum: SubjectType {
    return SubjectType(type)
  }

  init(
    uk: String, characterId: UInt, subjectId: UInt, staff: String, name: String, nameCn: String,
    type: UInt8, image: String
  ) {
    self.uk = uk
    self.characterId = characterId
    self.subjectId = subjectId
    self.staff = staff
    self.name = name
    self.nameCn = nameCn
    self.type = type
    self.image = image
  }

  init(_ item: CharacterSubjectDTO, characterId: UInt) {
    self.uk = "\(characterId)-\(item.id)"
    self.characterId = characterId
    self.subjectId = item.id
    self.staff = item.staff
    self.name = item.name ?? ""
    self.nameCn = item.nameCn
    self.type = 0  // TODO: add in API
    self.image = item.image
  }
}

@Model
final class CharacterRelatedPerson {
  @Attribute(.unique)
  var uk: String

  var characterId: UInt
  var personId: UInt
  var name: String
  var type: UInt8
  var images: Images
  var subjectId: UInt
  var subjectName: String
  var subjectNameCn: String
  var staff: String

  init(
    uk: String, characterId: UInt, personId: UInt, name: String, type: UInt8, images: Images,
    subjectId: UInt, subjectName: String, subjectNameCn: String, staff: String
  ) {
    self.uk = uk
    self.characterId = characterId
    self.personId = personId
    self.name = name
    self.type = type
    self.images = images
    self.subjectId = subjectId
    self.subjectName = subjectName
    self.subjectNameCn = subjectNameCn
    self.staff = staff
  }

  init(_ item: CharacterPersonDTO, characterId: UInt, sort: Float = 0) {
    self.uk = "\(characterId)-\(item.id)-\(item.subjectId)"
    self.characterId = characterId
    self.personId = item.id
    self.name = item.name
    self.type = item.type.rawValue
    self.images = item.images ?? Images()
    self.subjectId = item.subjectId
    self.subjectName = item.subjectName
    self.subjectNameCn = item.subjectNameCn
    self.staff = item.staff ?? ""
  }
}
