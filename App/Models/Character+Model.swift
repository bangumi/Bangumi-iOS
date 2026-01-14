import Foundation
import OSLog
import SwiftData
import SwiftUI

typealias Character = CharacterV2

@Model
final class CharacterV2: Searchable, Linkable {
  @Attribute(.unique)
  var characterId: Int

  var collects: Int
  var comment: Int
  var images: Images?
  var infobox: Infobox
  var lock: Bool
  var name: String
  var nameCN: String
  var nsfw: Bool
  var role: Int
  var summary: String
  var info: String = ""
  var alias: String = ""

  var collectedAt: Int = 0

  var casts: [CharacterCastDTO] = []
  var indexes: [SlimIndexDTO] = []

  var roleEnum: CharacterType {
    return CharacterType(role)
  }

  func title(with preference: TitlePreference) -> String {
    preference.title(name: name, nameCN: nameCN)
  }

  func subtitle(with preference: TitlePreference) -> String? {
    switch preference {
    case .chinese:
      return nameCN.isEmpty ? nil : (name != nameCN ? name : nil)
    case .original:
      return name.isEmpty ? nil : (nameCN != name && !nameCN.isEmpty ? nameCN : nil)
    }
  }

  var link: String {
    return "chii://character/\(characterId)"
  }

  var slim: SlimCharacterDTO {
    SlimCharacterDTO(
      id: characterId,
      images: images,
      lock: lock,
      name: name,
      nameCN: nameCN,
      nsfw: nsfw,
      role: roleEnum,
      info: info,
      comment: comment
    )
  }

  init(_ item: CharacterDTO) {
    self.characterId = item.id
    self.collects = item.collects
    self.comment = item.comment
    self.images = item.images
    self.infobox = item.infobox.clean()
    self.lock = item.lock
    self.name = item.name
    self.nameCN = item.nameCN
    self.nsfw = item.nsfw
    self.role = item.role.rawValue
    self.summary = item.summary
    self.info = item.info
    self.alias = item.infobox.aliases.joined(separator: " ")
    self.collectedAt = item.collectedAt ?? 0
  }

  init(_ item: SlimCharacterDTO) {
    self.characterId = item.id
    self.collects = 0
    self.comment = item.comment ?? 0
    self.images = item.images
    self.infobox = []
    self.lock = item.lock
    self.name = item.name
    self.nameCN = item.nameCN
    self.nsfw = item.nsfw
    self.role = item.role.rawValue
    self.info = item.info ?? ""
    self.summary = ""
    self.alias = ""
    self.collectedAt = 0
  }

  func update(_ item: CharacterDTO) {
    if self.collects != item.collects { self.collects = item.collects }
    if self.comment != item.comment { self.comment = item.comment }
    if self.images != item.images { self.images = item.images }
    if self.infobox != item.infobox.clean() { self.infobox = item.infobox.clean() }
    if self.lock != item.lock { self.lock = item.lock }
    if self.name != item.name { self.name = item.name }
    if self.nameCN != item.nameCN { self.nameCN = item.nameCN }
    if self.nsfw != item.nsfw { self.nsfw = item.nsfw }
    if self.role != item.role.rawValue { self.role = item.role.rawValue }
    if self.summary != item.summary { self.summary = item.summary }
    if self.info != item.info { self.info = item.info }
    let aliases = item.infobox.aliases.joined(separator: " ")
    if self.alias != aliases { self.alias = aliases }
    if let collectedAt = item.collectedAt, self.collectedAt != collectedAt {
      self.collectedAt = collectedAt
    }
  }

  func update(_ item: SlimCharacterDTO) {
    if let images = item.images, self.images != images { self.images = images }
    if self.name != item.name { self.name = item.name }
    if self.nameCN != item.nameCN { self.nameCN = item.nameCN }
    if self.nsfw != item.nsfw { self.nsfw = item.nsfw }
    if self.role != item.role.rawValue { self.role = item.role.rawValue }
    if let info = item.info, self.info != info { self.info = info }
    if let comment = item.comment, self.comment != comment { self.comment = comment }
  }
}
