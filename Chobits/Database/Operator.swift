import Foundation
import OSLog
import SwiftData

@ModelActor
actor DatabaseOperator {
}

// MARK: - basic
extension DatabaseOperator {
  public func commit() throws {
    try modelContext.save()
  }

  public func fetchOne<T: PersistentModel>(
    predicate: Predicate<T>? = nil,
    sortBy: [SortDescriptor<T>] = []
  ) throws -> T? {
    var fetchDescriptor = FetchDescriptor<T>(predicate: predicate, sortBy: sortBy)
    fetchDescriptor.fetchLimit = 1
    let list: [T] = try modelContext.fetch(fetchDescriptor)
    return list.first
  }
}

// MARK: - fetch
extension DatabaseOperator {
  public func getSubject(_ id: Int) throws -> Subject? {
    let subject = try self.fetchOne(
      predicate: #Predicate<Subject> {
        $0.subjectId == id
      }
    )
    return subject
  }

  public func getSubjectType(_ id: Int) throws -> SubjectType {
    let subject = try self.fetchOne(
      predicate: #Predicate<Subject> {
        $0.subjectId == id
      }
    )
    guard let subject = subject else {
      throw ChiiError(message: "subject not found: \(id)")
    }
    return subject.typeEnum
  }

  public func getEpisodeIDs(subjectId: Int, sort: Float) throws -> [Int] {
    let descriptor = FetchDescriptor<Episode>(
      predicate: #Predicate<Episode> {
        $0.subjectId == subjectId && $0.sort <= sort
      })
    let episodes = try modelContext.fetch(descriptor)
    return episodes.map { $0.episodeId }
  }

  public func getSearchable<T: PersistentModel & Searchable>(
    _ type: T.Type,
    limit: Int = 20,
    offset: Int = 0
  ) throws -> PagedDTO<SearchableItem> {
    let total = try modelContext.fetchCount(FetchDescriptor<T>())
    var descriptor = FetchDescriptor<T>()
    descriptor.fetchLimit = limit
    descriptor.fetchOffset = offset
    let items = try modelContext.fetch(descriptor)
    return PagedDTO(
      data: items.map { $0.searchable() },
      total: total
    )
  }
}

// MARK: - delete,update user collection
extension DatabaseOperator {
  public func deleteUserCollection(subjectId: Int) throws {
    try modelContext.delete(
      model: UserSubjectCollection.self,
      where: #Predicate<UserSubjectCollection> {
        $0.subjectId == subjectId
      })
    let episodes = try modelContext.fetch(
      FetchDescriptor<Episode>(
        predicate: #Predicate<Episode> {
          $0.subjectId == subjectId
        }))
    for episode in episodes {
      episode.collection = EpisodeCollectionType.none.rawValue
    }
  }

  public func updateEpisodeCollections(subjectId: Int, sort: Float, type: EpisodeCollectionType)
    throws
  {
    let descriptor = FetchDescriptor<Episode>(
      predicate: #Predicate<Episode> {
        $0.subjectId == subjectId && $0.sort <= sort
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
    collection?.updatedAt = Date() - 1
  }

  public func updateEpisodeCollection(subjectId: Int, episodeId: Int, type: EpisodeCollectionType)
    throws
  {
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
    collection?.updatedAt = Date() - 1
  }
}

// MARK: - ensure
extension DatabaseOperator {
  public func ensureSubject(_ item: SubjectDTO) throws -> Subject {
    let sid = item.id
    let fetched = try self.fetchOne(
      predicate: #Predicate<Subject> {
        $0.subjectId == sid
      })
    if let subject = fetched {
      subject.update(item)
      return subject
    }
    let subject = Subject(item)
    modelContext.insert(subject)
    return subject
  }

  public func ensureSubject(_ item: SubjectDTOV0) throws -> Subject {
    let sid = item.id
    let fetched = try self.fetchOne(
      predicate: #Predicate<Subject> {
        $0.subjectId == sid
      })
    if let subject = fetched {
      subject.update(item)
      return subject
    }
    let subject = Subject(item)
    modelContext.insert(subject)
    return subject
  }

  public func ensureEpisode(_ item: EpisodeDTO) throws -> Episode {
    let eid = item.id
    let fetched = try self.fetchOne(
      predicate: #Predicate<Episode> {
        $0.episodeId == eid
      })
    if let episode = fetched {
      episode.update(item)
      return episode
    }
    let episode = Episode(item)
    modelContext.insert(episode)
    return episode
  }

  public func ensureCharacter(_ item: CharacterDTO) throws -> Character {
    let cid = item.id
    let fetched = try self.fetchOne(
      predicate: #Predicate<Character> {
        $0.characterId == cid
      })
    if let character = fetched {
      character.update(item)
      return character
    }
    let character = Character(item)
    modelContext.insert(character)
    return character
  }

  public func ensurePerson(_ item: PersonDTO) throws -> Person {
    let pid = item.id
    let fetched = try self.fetchOne(
      predicate: #Predicate<Person> {
        $0.personId == pid
      })
    if let person = fetched {
      person.update(item)
      return person
    }
    let person = Person(item)
    modelContext.insert(person)
    return person
  }

  public func ensureUserSubjectCollection(_ item: UserSubjectCollectionDTO) throws
    -> UserSubjectCollection
  {
    let sid = item.subject.id
    let fetched = try self.fetchOne(
      predicate: #Predicate<UserSubjectCollection> {
        $0.subjectId == sid
      })
    if let collection = fetched {
      collection.update(item)
      return collection
    }
    let collection = UserSubjectCollection(item)
    modelContext.insert(collection)
    return collection
  }

  public func ensureUserCharacterCollection(_ item: UserCharacterCollectionDTO) throws
    -> UserCharacterCollection
  {
    let cid = item.character.id
    let fetched = try self.fetchOne(
      predicate: #Predicate<UserCharacterCollection> {
        $0.characterId == cid
      })
    if let collection = fetched {
      collection.update(item)
      return collection
    }
    let collection = UserCharacterCollection(item)
    modelContext.insert(collection)
    return collection
  }

  public func ensureUserPersonCollection(_ item: UserPersonCollectionDTO) throws
    -> UserPersonCollection
  {
    let pid = item.person.id
    let fetched = try self.fetchOne(
      predicate: #Predicate<UserPersonCollection> {
        $0.personId == pid
      })
    if let collection = fetched {
      collection.update(item)
      return collection
    }
    let collection = UserPersonCollection(item)
    modelContext.insert(collection)
    return collection
  }
}

// MARK: - save
extension DatabaseOperator {
  public func saveCalendarItem(weekday: Int, items: [BangumiCalendarItemDTO]) throws {
    let cal = BangumiCalendar(weekday: weekday, items: items)
    modelContext.insert(cal)
  }

  public func saveSubject(_ item: SubjectDTO) throws {
    let _ = try self.ensureSubject(item)
  }

  public func saveSubject(_ item: SubjectDTOV0) throws {
    let _ = try self.ensureSubject(item)
  }

  public func saveUserSubjectCollection(_ item: UserSubjectCollectionDTO) throws {
    let subject = try self.ensureSubject(item.subject)
    let collection = try self.ensureUserSubjectCollection(item)
    if collection.subject == nil {
      collection.subject = subject
    }
  }

  public func saveEpisode(_ item: EpisodeDTO) throws {
    let _ = try self.ensureEpisode(item)
  }

  public func saveEpisode(_ item: EpisodeCollectionDTO) throws {
    let episode = try self.ensureEpisode(item.episode)
    if episode.collection != item.type.rawValue {
      episode.collection = item.type.rawValue
    }
  }

  public func saveCharacter(_ item: CharacterDTO) throws {
    let _ = try self.ensureCharacter(item)
  }

  public func savePerson(_ item: PersonDTO) throws {
    let _ = try self.ensurePerson(item)
  }

  public func saveUserCharacterCollection(_ item: UserCharacterCollectionDTO) throws {
    let character = try self.ensureCharacter(item.character)
    let collection = try self.ensureUserCharacterCollection(item)
    if collection.character == nil {
      collection.character = character
    }
  }

  public func saveUserPersonCollection(_ item: UserPersonCollectionDTO) throws {
    let person = try self.ensurePerson(item.person)
    let collection = try self.ensureUserPersonCollection(item)
    if collection.person == nil {
      collection.person = person
    }
  }
}
