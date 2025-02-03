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

  public func truncate<T: PersistentModel>(_ model: T.Type) throws {
    try modelContext.delete(model: model)
  }

  public func clearSubjectInterest() throws {
    let subjects = try modelContext.fetch(FetchDescriptor<Subject>())
    for subject in subjects {
      subject.interest = SubjectInterest()
    }
  }

  public func clearEpisodeCollection() throws {
    let episodes = try modelContext.fetch(FetchDescriptor<Episode>())
    for episode in episodes {
      episode.collection = nil
    }
  }

  public func clearPersonCollection() throws {
    let persons = try modelContext.fetch(FetchDescriptor<Person>())
    for person in persons {
      person.collectedAt = nil
    }
  }

  public func clearCharacterCollection() throws {
    let characters = try modelContext.fetch(FetchDescriptor<Character>())
    for character in characters {
      character.collectedAt = nil
    }
  }
}

// MARK: - fetch
extension DatabaseOperator {
  public func getUser(_ username: String) throws -> User? {
    let user = try self.fetchOne(
      predicate: #Predicate<User> {
        $0.username == username
      }
    )
    return user
  }

  public func getSubject(_ id: Int) throws -> Subject? {
    let subject = try self.fetchOne(
      predicate: #Predicate<Subject> {
        $0.subjectId == id
      }
    )
    return subject
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
    descriptor: FetchDescriptor<T>,
    limit: Int = 50,
    offset: Int = 0
  ) throws -> PagedDTO<SearchableItem> {
    let total = try modelContext.fetchCount(descriptor)
    var desc = descriptor
    desc.fetchLimit = limit
    desc.fetchOffset = offset
    let items = try modelContext.fetch(desc)
    return PagedDTO(
      data: items.map { $0.searchable() },
      total: total
    )
  }
}

// MARK: - delete,update user collection
extension DatabaseOperator {
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
    let subject = try self.fetchOne(
      predicate: #Predicate<Subject> {
        $0.subjectId == subjectId
      }
    )
    subject?.interest.updatedAt = Int(Date().timeIntervalSince1970) - 1
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
    let subject = try self.fetchOne(
      predicate: #Predicate<Subject> {
        $0.subjectId == subjectId
      }
    )
    subject?.interest.updatedAt = Int(Date().timeIntervalSince1970) - 1
  }
}

// MARK: - ensure
extension DatabaseOperator {
  public func ensureUser(_ item: UserDTO) throws -> User {
    let uid = item.id
    let fetched = try self.fetchOne(
      predicate: #Predicate<User> {
        $0.userId == uid
      })
    if let user = fetched {
      user.update(item)
      return user
    }
    let user = User(item)
    modelContext.insert(user)
    return user
  }

  public func ensureCalendarItem(_ weekday: Int, items: [BangumiCalendarItemDTO])
    throws -> BangumiCalendar
  {
    let fetched = try self.fetchOne(
      predicate: #Predicate<BangumiCalendar> {
        $0.weekday == weekday
      })
    if let calendar = fetched {
      if calendar.items != items {
        calendar.items = items
      }
      return calendar
    }
    let calendar = BangumiCalendar(weekday: weekday, items: items)
    modelContext.insert(calendar)
    return calendar
  }

  public func ensureTrendingSubject(_ type: Int, items: [TrendingSubjectDTO])
    throws -> TrendingSubject
  {
    let fetched = try self.fetchOne(
      predicate: #Predicate<TrendingSubject> {
        $0.type == type
      })
    if let trending = fetched {
      if trending.items != items {
        trending.items = items
      }
      return trending
    }
    let trending = TrendingSubject(type: type, items: items)
    modelContext.insert(trending)
    return trending
  }

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

  public func ensureSubject(_ item: SlimSubjectDTO) throws -> Subject {
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
      if episode.subject == nil, let subject = item.subject {
        let subject = try self.ensureSubject(subject)
        if episode.subject == nil {
          episode.subject = subject
        }
      }
      return episode
    }
    let episode = Episode(item)
    modelContext.insert(episode)
    if let slim = item.subject {
      let subject = try self.ensureSubject(slim)
      if episode.subject == nil {
        episode.subject = subject
      }
    } else {
      let subject = try self.getSubject(item.subjectID)
      if episode.subject == nil, let subject = subject {
        episode.subject = subject
      }
    }
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
}

// MARK: - save
extension DatabaseOperator {
  public func saveUser(_ item: UserDTO) throws {
    let _ = try self.ensureUser(item)
  }

  public func saveCalendarItem(weekday: Int, items: [BangumiCalendarItemDTO]) throws {
    _ = try self.ensureCalendarItem(weekday, items: items)
  }

  public func saveTrendingSubjects(type: Int, items: [TrendingSubjectDTO]) throws {
    _ = try self.ensureTrendingSubject(type, items: items)
  }

  public func saveSubject(_ item: SubjectDTO) throws {
    let _ = try self.ensureSubject(item)
  }

  public func saveSubject(_ item: SubjectDTOV0) throws {
    let _ = try self.ensureSubject(item)
  }

  public func saveEpisode(_ item: EpisodeDTO) throws {
    let _ = try self.ensureEpisode(item)
  }

  public func saveCharacter(_ item: CharacterDTO) throws {
    let _ = try self.ensureCharacter(item)
  }

  public func savePerson(_ item: PersonDTO) throws {
    let _ = try self.ensurePerson(item)
  }
}
