//
//  Operator.swift
//  Chobits
//
//  Created by Chuan Chuan on 2024/10/3.
//

import OSLog
import Foundation
import SwiftData

@ModelActor
actor DatabaseOperator {
}

extension DatabaseOperator {
  public func commit() throws {
    try modelContext.save()
  }

  func fetchOne<T: PersistentModel>(
    predicate: Predicate<T>? = nil,
    sortBy: [SortDescriptor<T>] = []
  ) throws -> T? {
    var fetchDescriptor = FetchDescriptor<T>(predicate: predicate, sortBy: sortBy)
    fetchDescriptor.fetchLimit = 1
    let list: [T] = try modelContext.fetch(fetchDescriptor)
    return list.first
  }

  func insertIfNeeded<T: PersistentModel>(
    data: T,
    predicate: Predicate<T>
  ) throws {
    let descriptor = FetchDescriptor<T>(predicate: predicate)
    let savedCount = try modelContext.fetchCount(descriptor)
    if savedCount == 0 {
      modelContext.insert(data)
    }
  }
}

extension DatabaseOperator {
  public func saveCalendar(_ items: [BangumiCalendarDTO]) throws {
    for item in items {
      Logger.db.info("processing calendar: \(item.weekday.en)")
      let cal = BangumiCalendar(item)
      modelContext.insert(cal)
      for small in item.items {
        let subject = Subject(small)
        let sid = small.id
        try self.insertIfNeeded(
          data: subject,
          predicate: #Predicate<Subject> {
            $0.subjectId == sid
          })
      }
    }
  }

  public func saveSubject(_ item: SubjectDTO) throws {
    let subject = Subject(item)
    modelContext.insert(subject)
  }

  public func saveSubject(_ item: SlimSubject) throws {
    let subject = Subject(item)
    let subjectID = item.id
    try self.insertIfNeeded(
      data: subject,
      predicate: #Predicate<Subject> {
        $0.subjectId == subjectID
      })
  }

  public func saveSubject(_ item: SearchSubject) throws {
    let subject = Subject(item)
    let subjectID = item.id
    try self.insertIfNeeded(
      data: subject,
      predicate: #Predicate<Subject> {
        $0.subjectId == subjectID
      })
  }

  public func saveSubject(_ item: SubjectRelationDTO) throws {
    let subject = Subject(item)
    let subjectID = item.id
    try self.insertIfNeeded(
      data: subject,
      predicate: #Predicate<Subject> {
        $0.subjectId == subjectID
      })
  }

  public func saveSubject(_ item: CharacterSubjectDTO) throws {
    let subject = Subject(item)
    let subjectID = item.id
    try self.insertIfNeeded(
      data: subject,
      predicate: #Predicate<Subject> {
        $0.subjectId == subjectID
      })
  }

  public func saveSubject(_ item: CharacterPersonDTO) throws {
    let subject = Subject(item)
    let subjectID = item.id
    try self.insertIfNeeded(
      data: subject,
      predicate: #Predicate<Subject> {
        $0.subjectId == subjectID
      })
  }

  public func saveSubject(_ item: PersonSubjectDTO) throws {
    let subject = Subject(item)
    let subjectID = item.id
    try self.insertIfNeeded(
      data: subject,
      predicate: #Predicate<Subject> {
        $0.subjectId == subjectID
      })
  }

  public func saveSubject(_ item: PersonCharacterDTO) throws {
    let subject = Subject(item)
    let subjectID = item.id
    try self.insertIfNeeded(
      data: subject,
      predicate: #Predicate<Subject> {
        $0.subjectId == subjectID
      })
  }

  public func saveSubjectRelation(_ item: SubjectRelationDTO, subjectId: UInt, sort: Float) throws {
    let relation = SubjectRelation(item, subjectId: subjectId, sort: sort)
    modelContext.insert(relation)
  }

  public func saveUserCollection(_ item: UserSubjectCollectionDTO) throws {
    let collection = UserSubjectCollection(item)
    modelContext.insert(collection)
  }

  public func saveEpisode(_ item: EpisodeDTO, subjectId: UInt) throws {
    let episode = Episode(item, subjectId: subjectId)
    modelContext.insert(episode)
  }

  public func saveEpisode(_ item: EpisodeCollectionDTO, subjectId: UInt) throws {
    let episode = Episode(item, subjectId: subjectId)
    modelContext.insert(episode)
  }

  public func saveSubjectCharacter(_ item: SubjectCharacterDTO, subjectId: UInt, sort: Float) throws {
    let character = SubjectRelatedCharacter(item, subjectId: subjectId, sort: sort)
    modelContext.insert(character)
  }

  public func saveSubjectPerson(_ item: SubjectPersonDTO, subjectId: UInt, sort: Float) throws {
    let person = SubjectRelatedPerson(item, subjectId: subjectId, sort: sort)
    modelContext.insert(person)
  }

  public func saveCharacter(_ item: CharacterDTO) throws {
    let character = Character(item)
    modelContext.insert(character)
  }

  public func saveCharacter(_ item: SubjectCharacterDTO) throws {
    let character = Character(item)
    let characterId = character.characterId
    try self.insertIfNeeded(
      data: character,
      predicate: #Predicate<Character> {
        $0.characterId == characterId
      })
  }

  public func saveCharacter(_ item: PersonCharacterDTO) throws {
    let character = Character(item)
    let characterId = character.characterId
    try self.insertIfNeeded(
      data: character,
      predicate: #Predicate<Character> {
        $0.characterId == characterId
      })
  }

  public func saveCharacterSubject(_ item: CharacterSubjectDTO, characterId: UInt) throws {
    let character = CharacterRelatedSubject(item, characterId: characterId)
    modelContext.insert(character)
  }

  public func saveCharacterPerson(_ item: CharacterPersonDTO, characterId: UInt) throws {
    let person = CharacterRelatedPerson(item, characterId: characterId)
    modelContext.insert(person)
  }

  public func savePerson(_ item: SubjectCharacterActorItem) throws {
    let person = Person(item)
    let personId = person.personId
    try self.insertIfNeeded(
      data: person,
      predicate: #Predicate<Person> {
        $0.personId == personId
      })
  }

  public func savePerson(_ item: PersonDTO) throws {
    let person = Person(item)
    modelContext.insert(person)
  }

  public func savePerson(_ itme: SubjectPersonDTO) throws {
    let person = Person(itme)
    let personId = person.personId
    try self.insertIfNeeded(
      data: person,
      predicate: #Predicate<Person> {
        $0.personId == personId
      })
  }

  public func savePerson(_ item: CharacterPersonDTO) throws {
    let person = Person(item)
    let personId = person.personId
    try self.insertIfNeeded(
      data: person,
      predicate: #Predicate<Person> {
        $0.personId == personId
      })
  }

  public func savePersonSubject(_ item: PersonSubjectDTO, personId: UInt) throws {
    let person = PersonRelatedSubject(item, personId: personId)
    modelContext.insert(person)
  }

  public func savePersonCharacter(_ item: PersonCharacterDTO, personId: UInt) throws {
    let person = PersonRelatedCharacter(item, personId: personId)
    modelContext.insert(person)
  }

}


extension DatabaseOperator {
  public func updateUserCollection(sid: UInt, eps: UInt?, vols: UInt?) throws {
    let collection = try self.fetchOne(
      predicate: #Predicate<UserSubjectCollection> {
        $0.subjectId == sid
      }
    )
    if let eps = eps {
      collection?.epStatus = eps
    }
    if let vols = vols {
      collection?.volStatus = vols
    }
    collection?.updatedAt = Date()
  }

  public func updateUserCollection(sid: UInt, type: CollectionType?, rate: UInt8?, comment: String?,
                                   priv: Bool?, tags: [String]?) throws {
    let collection = try self.fetchOne(
      predicate: #Predicate<UserSubjectCollection> {
        $0.subjectId == sid
      }
    )
    if let type = type {
      collection?.type = type.rawValue
    }
    if let rate = rate {
      collection?.rate = rate
    }
    if let comment = comment {
      collection?.comment = comment
    }
    if let priv = priv {
      collection?.priv = priv
    }
    if let tags = tags {
      collection?.tags = tags
    }
    collection?.updatedAt = Date()
  }

  public func getEpisodeIDs(subjectId: UInt, sort: Float) throws -> [UInt] {
    let descriptor = FetchDescriptor<Episode>(predicate: #Predicate<Episode> {
      $0.subjectId == subjectId && $0.sort < sort
    })
    let episodes = try modelContext.fetch(descriptor)
    return episodes.map { $0.episodeId }
  }

  public func updateEpisodeCollections(subjectId: UInt, sort: Float, type: EpisodeCollectionType) throws {
    let descriptor = FetchDescriptor<Episode>(predicate: #Predicate<Episode> {
      $0.subjectId == subjectId && $0.sort < sort
    })
    let episodes = try modelContext.fetch(descriptor)
    for episode in episodes {
      episode.collection = type.rawValue
    }
    let collection = try self.fetchOne(
      predicate: #Predicate<UserSubjectCollection> {
        $0.subjectId == subjectId
      }
    )
    collection?.updatedAt = Date()
  }

  public func updateEpisodeCollection(subjectId: UInt, episodeId: UInt, type: EpisodeCollectionType) throws {
    let episode = try self.fetchOne(
      predicate: #Predicate<Episode> {
        $0.episodeId == episodeId
      }
    )
    episode?.collection = type.rawValue
    let collection = try self.fetchOne(
      predicate: #Predicate<UserSubjectCollection> {
        $0.subjectId == subjectId
      }
    )
    collection?.updatedAt = Date()
  }

}
