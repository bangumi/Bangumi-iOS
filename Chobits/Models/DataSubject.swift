//
//  Subject.swift
//  Chobits
//
//  Created by Chuan Chuan on 2024/5/8.
//

import Foundation
import SwiftData

@Model
final class Subject {
  @Attribute(.unique)
  var subjectId: UInt
  var type: UInt8
  var name: String
  var nameCn: String
  var summary: String
  var nsfw: Bool
  var locked: Bool
  var date: Date
  var platform: String
  var images: SubjectImages
  var infobox: [InfoboxItem]
  var volumes: UInt
  var eps: UInt
  var totalEpisodes: UInt
  var rating: Rating
  var collection: SubjectCollection
  var tags: [Tag]

  var typeEnum: SubjectType {
    return SubjectType(type)
  }

  init(
    subjectId: UInt, type: UInt8, name: String, nameCn: String, summary: String, nsfw: Bool,
    locked: Bool,
    date: Date, platform: String, images: SubjectImages, infobox: [InfoboxItem], volumes: UInt,
    eps: UInt, totalEpisodes: UInt, rating: Rating, collection: SubjectCollection, tags: [Tag]
  ) {
    self.subjectId = subjectId
    self.type = type
    self.name = name
    self.nameCn = nameCn
    self.summary = summary
    self.nsfw = nsfw
    self.locked = locked
    self.date = date
    self.platform = platform
    self.images = images
    self.infobox = infobox
    self.volumes = volumes
    self.eps = eps
    self.totalEpisodes = totalEpisodes
    self.rating = rating
    self.collection = collection
    self.tags = tags
  }

  init(_ item: SubjectDTO) {
    self.subjectId = item.id
    self.type = item.type.rawValue
    self.name = item.name
    self.nameCn = item.nameCn
    self.summary = item.summary
    self.nsfw = item.nsfw
    self.locked = item.locked
    self.date = safeParseDate(str: item.date)
    self.platform = item.platform
    self.images = item.images
    self.infobox = item.infobox ?? []
    self.volumes = item.volumes
    self.eps = item.eps
    self.totalEpisodes = item.totalEpisodes
    self.rating = item.rating
    self.collection = item.collection
    self.tags = item.tags
  }

  init(_ slim: SlimSubject) {
    self.subjectId = slim.id
    self.type = slim.type.rawValue
    self.name = slim.name
    self.nameCn = slim.nameCn
    self.summary = ""
    self.nsfw = false
    self.locked = false
    self.date = safeParseDate(str: slim.date)
    self.platform = ""
    self.images = slim.images
    self.infobox = []
    self.volumes = slim.volumes
    self.eps = slim.eps
    self.totalEpisodes = 0
    self.rating = Rating(rank: 0, total: 0, count: [:], score: slim.score)
    self.collection = SubjectCollection()
    self.tags = slim.tags
  }

  init(_ search: SearchSubject) {
    self.subjectId = search.id
    self.type = search.type?.rawValue ?? 0
    self.name = search.name
    self.nameCn = search.nameCn
    self.summary = search.summary
    self.nsfw = false
    self.locked = false
    self.date = safeParseDate(str: search.date)
    self.platform = ""
    self.images = SubjectImages(image: search.image)
    self.infobox = []
    self.volumes = 0
    self.eps = 0
    self.totalEpisodes = 0
    self.rating = Rating(rank: search.rank, total: 0, count: [:], score: search.score)
    self.collection = SubjectCollection()
    self.tags = search.tags
  }

  init(_ small: SmallSubject) {
    self.subjectId = small.id
    self.type = small.type.rawValue
    self.name = small.name
    self.nameCn = small.nameCn
    self.summary = small.summary
    self.nsfw = false
    self.locked = false
    self.date = safeParseDate(str: small.airDate)
    self.platform = ""
    self.images = small.images ?? SubjectImages()
    self.infobox = []
    self.volumes = 0
    self.eps = 0
    self.totalEpisodes = 0
    var rating = Rating(rank: small.rank ?? 0, total: 0, count: [:], score: 0)
    if let smallRating = small.rating {
      rating.score = smallRating.score
      rating.count = smallRating.count
      rating.total = smallRating.total
    }
    self.rating = rating
    self.collection = SubjectCollection()
    self.tags = []
  }

  init(_ relation: SubjectRelationDTO) {
    self.subjectId = relation.id
    self.type = relation.type.rawValue
    self.name = relation.name
    self.nameCn = relation.nameCn
    self.summary = ""
    self.nsfw = false
    self.locked = false
    self.date = Date()
    self.platform = ""
    self.images = relation.images ?? SubjectImages()
    self.infobox = []
    self.volumes = 0
    self.eps = 0
    self.totalEpisodes = 0
    self.rating = Rating(rank: 0, total: 0, count: [:], score: 0)
    self.collection = SubjectCollection()
    self.tags = []
  }

  init(_ item: CharacterSubjectDTO) {
    self.subjectId = item.id
    self.type = 0
    self.name = item.name ?? ""
    self.nameCn = item.nameCn
    self.summary = ""
    self.nsfw = false
    self.locked = false
    self.date = Date()
    self.platform = ""
    self.images = SubjectImages(image: item.image)
    self.infobox = []
    self.volumes = 0
    self.eps = 0
    self.totalEpisodes = 0
    self.rating = Rating(rank: 0, total: 0, count: [:], score: 0)
    self.collection = SubjectCollection()
    self.tags = []
  }

  init(_ item: CharacterPersonDTO) {
    self.subjectId = item.subjectId
    self.type = 0
    self.name = item.subjectName
    self.nameCn = item.subjectNameCn
    self.summary = ""
    self.nsfw = false
    self.locked = false
    self.date = Date()
    self.platform = ""
    self.images = SubjectImages()
    self.infobox = []
    self.volumes = 0
    self.eps = 0
    self.totalEpisodes = 0
    self.rating = Rating(rank: 0, total: 0, count: [:], score: 0)
    self.collection = SubjectCollection()
    self.tags = []
  }

  init(_ item: PersonSubjectDTO) {
    self.subjectId = item.id
    self.type = 0
    self.name = item.name ?? ""
    self.nameCn = item.nameCn
    self.summary = ""
    self.nsfw = false
    self.locked = false
    self.date = Date()
    self.platform = ""
    self.images = SubjectImages(image: item.image ?? "")
    self.infobox = []
    self.volumes = 0
    self.eps = 0
    self.totalEpisodes = 0
    self.rating = Rating(rank: 0, total: 0, count: [:], score: 0)
    self.collection = SubjectCollection()
    self.tags = []
  }

  init(_ item: PersonCharacterDTO) {
    self.subjectId = item.subjectId
    self.type = 0
    self.name = item.subjectName
    self.nameCn = item.subjectNameCn
    self.summary = ""
    self.nsfw = false
    self.locked = false
    self.date = Date()
    self.platform = ""
    self.images = SubjectImages()
    self.infobox = []
    self.volumes = 0
    self.eps = 0
    self.totalEpisodes = 0
    self.rating = Rating(rank: 0, total: 0, count: [:], score: 0)
    self.collection = SubjectCollection()
    self.tags = []
  }
}

@Model
final class SubjectRelation {
  @Attribute(.unique)
  var uk: String

  var subjectId: UInt
  var relationId: UInt
  var type: UInt8
  var name: String
  var nameCn: String
  var images: SubjectImages
  var relation: String
  var sort: Float

  var typeEnum: SubjectType {
    return SubjectType(type)
  }

  init(
    uk: String, subjectId: UInt, relationId: UInt, type: UInt8, name: String, nameCn: String,
    images: SubjectImages, relation: String, sort: Float
  ) {
    self.uk = uk
    self.subjectId = subjectId
    self.relationId = relationId
    self.type = type
    self.name = name
    self.nameCn = nameCn
    self.images = images
    self.relation = relation
    self.sort = sort
  }

  init(_ item: SubjectRelationDTO, subjectId: UInt, sort: Float = 0) {
    self.uk = "\(subjectId)-\(item.id)"
    self.subjectId = subjectId
    self.relationId = item.id
    self.type = item.type.rawValue
    self.name = item.name
    self.nameCn = item.nameCn
    self.images = item.images ?? SubjectImages()
    self.relation = item.relation
    self.sort = sort
  }
}

@Model
final class SubjectRelatedCharacter {
  @Attribute(.unique)
  var uk: String

  var subjectId: UInt
  var characterId: UInt
  var type: UInt8
  var name: String
  var images: Images
  var relation: String
  var actors: [SubjectCharacterActorItem]
  var sort: Float

  var typeEnum: CharacterType {
    return CharacterType(type)
  }

  init(
    uk: String, subjectId: UInt, characterId: UInt, type: UInt8, name: String, images: Images,
    relation: String, actors: [SubjectCharacterActorItem], sort: Float
  ) {
    self.uk = uk
    self.subjectId = subjectId
    self.characterId = characterId
    self.type = type
    self.name = name
    self.images = images
    self.relation = relation
    self.actors = actors
    self.sort = sort
  }

  init(_ item: SubjectCharacterDTO, subjectId: UInt, sort: Float = 0) {
    self.uk = "\(subjectId)-\(item.id)"
    self.subjectId = subjectId
    self.characterId = item.id
    self.type = item.type.rawValue
    self.name = item.name
    self.images = item.images ?? Images()
    self.relation = item.relation
    self.actors = item.actors ?? []
    self.sort = sort
  }
}

@Model
final class SubjectRelatedPerson {
  @Attribute(.unique)
  var uk: String

  var subjectId: UInt
  var personId: UInt
  var type: UInt8
  var name: String
  var images: Images
  var relation: String
  var sort: Float

  var typeEnum: PersonType {
    return PersonType(type)
  }

  init(
    uk: String, subjectId: UInt, personId: UInt, type: UInt8, name: String, images: Images,
    relation: String, sort: Float
  ) {
    self.uk = uk
    self.subjectId = subjectId
    self.personId = personId
    self.type = type
    self.name = name
    self.images = images
    self.relation = relation
    self.sort = sort
  }

  init(_ item: SubjectPersonDTO, subjectId: UInt, sort: Float = 0) {
    self.uk = "\(subjectId)-\(item.id)"
    self.subjectId = subjectId
    self.personId = item.id
    self.type = item.type.rawValue
    self.name = item.name
    self.images = item.images ?? Images()
    self.relation = item.relation
    self.sort = sort
  }
}
