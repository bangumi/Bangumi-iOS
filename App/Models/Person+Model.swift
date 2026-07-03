import Foundation

final class Person: Searchable, Linkable {
  var personId: Int

  var career: [String]
  var collects: Int
  var comment: Int
  var images: Images?
  var infobox: Infobox
  var lock: Bool
  var name: String
  var nameCN: String
  var nsfw: Bool
  var summary: String
  var type: Int
  var info: String = ""
  var alias: String = ""

  var collectedAt: Int = 0

  var castsData: Data?
  var worksData: Data?
  var relationsData: Data?
  var indexesData: Data?

  init(_ item: PersonDTO) {
    personId = item.id
    career = item.career.map(\.rawValue)
    collects = item.collects
    comment = item.comment
    images = item.images
    infobox = item.infobox.clean()
    lock = item.lock
    name = item.name
    nameCN = item.nameCN
    nsfw = item.nsfw
    summary = item.summary
    type = item.type.rawValue
    info = item.info
    alias = item.infobox.aliases.joined(separator: " ")
    collectedAt = item.collectedAt ?? 0
  }

  init(_ item: SlimPersonDTO) {
    personId = item.id
    career = []
    collects = 0
    comment = item.comment ?? 0
    images = item.images
    infobox = []
    lock = item.lock
    name = item.name
    nameCN = item.nameCN
    nsfw = item.nsfw
    summary = ""
    info = item.info ?? ""
    type = item.type.rawValue
    alias = ""
    collectedAt = 0
  }
}

extension Person {
  var casts: [PersonCastDTO] {
    get { PersistedJSON.decode([PersonCastDTO].self, from: castsData) ?? [] }
    set { castsData = PersistedJSON.encode(newValue) ?? castsData }
  }

  var works: [PersonWorkDTO] {
    get { PersistedJSON.decode([PersonWorkDTO].self, from: worksData) ?? [] }
    set { worksData = PersistedJSON.encode(newValue) ?? worksData }
  }

  var relations: [PersonRelationDTO] {
    get { PersistedJSON.decode([PersonRelationDTO].self, from: relationsData) ?? [] }
    set { relationsData = PersistedJSON.encode(newValue) ?? relationsData }
  }

  var indexes: [SlimIndexDTO] {
    get { PersistedJSON.decode([SlimIndexDTO].self, from: indexesData) ?? [] }
    set { indexesData = PersistedJSON.encode(newValue) ?? indexesData }
  }

  var typeEnum: PersonType {
    return PersonType(type)
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
    return "chii://person/\(personId)"
  }

  var slim: SlimPersonDTO {
    SlimPersonDTO(
      id: personId,
      name: name,
      nameCN: nameCN,
      type: typeEnum,
      career: career.compactMap { PersonCareer(rawValue: $0) },
      images: images,
      lock: lock,
      nsfw: nsfw,
      comment: comment,
      info: info
    )
  }

  func update(_ item: PersonDTO) {
    let newCareer = item.career.map(\.rawValue)
    if self.career != newCareer { self.career = newCareer }
    if self.collects != item.collects { self.collects = item.collects }
    if self.comment != item.comment { self.comment = item.comment }
    if self.images != item.images { self.images = item.images }
    if self.infobox != item.infobox.clean() { self.infobox = item.infobox.clean() }
    if self.lock != item.lock { self.lock = item.lock }
    if self.name != item.name { self.name = item.name }
    if self.nameCN != item.nameCN { self.nameCN = item.nameCN }
    if self.nsfw != item.nsfw { self.nsfw = item.nsfw }
    if self.summary != item.summary { self.summary = item.summary }
    if self.type != item.type.rawValue { self.type = item.type.rawValue }
    if self.info != item.info { self.info = item.info }
    let aliases = item.infobox.aliases.joined(separator: " ")
    if self.alias != aliases { self.alias = aliases }
    if let collectedAt = item.collectedAt, self.collectedAt != collectedAt {
      self.collectedAt = collectedAt
    }
  }

  func update(_ item: SlimPersonDTO) {
    if let images = item.images, self.images != images { self.images = images }
    if self.name != item.name { self.name = item.name }
    if self.nameCN != item.nameCN { self.nameCN = item.nameCN }
    if let comment = item.comment, self.comment != comment { self.comment = comment }
    if self.type != item.type.rawValue { self.type = item.type.rawValue }
    if self.nsfw != item.nsfw { self.nsfw = item.nsfw }
    if self.lock != item.lock { self.lock = item.lock }
    if let info = item.info, self.info != info { self.info = info }
  }
}
