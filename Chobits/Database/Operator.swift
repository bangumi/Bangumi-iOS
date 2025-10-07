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
      subject.ctype = 0
      subject.collectedAt = 0
      subject.interest = nil
    }
  }

  public func clearEpisodeCollection() throws {
    let episodes = try modelContext.fetch(FetchDescriptor<Episode>())
    for episode in episodes {
      episode.status = 0
    }
  }

  public func clearPersonCollection() throws {
    let persons = try modelContext.fetch(FetchDescriptor<Person>())
    for person in persons {
      person.collectedAt = 0
    }
  }

  public func clearCharacterCollection() throws {
    let characters = try modelContext.fetch(FetchDescriptor<Character>())
    for character in characters {
      character.collectedAt = 0
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

  public func getCharacter(_ id: Int) throws -> Character? {
    let character = try self.fetchOne(
      predicate: #Predicate<Character> {
        $0.characterId == id
      }
    )
    return character
  }

  public func getPerson(_ id: Int) throws -> Person? {
    let person = try self.fetchOne(
      predicate: #Predicate<Person> {
        $0.personId == id
      }
    )
    return person
  }

  public func getGroup(_ name: String) throws -> Group? {
    let group = try self.fetchOne(
      predicate: #Predicate<Group> {
        $0.name == name
      }
    )
    return group
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

// MARK: - update user collection
extension DatabaseOperator {
  public func updateSubjectProgress(subjectId: Int, eps: Int?, vols: Int?) throws {
    let subject = try self.fetchOne(
      predicate: #Predicate<Subject> {
        $0.subjectId == subjectId
      }
    )
    guard let subject = subject else {
      return
    }
    if let eps = eps {
      subject.interest?.epStatus = eps
    }
    if let vols = vols {
      subject.interest?.volStatus = vols
    }
    let now = Int(Date().timeIntervalSince1970)
    subject.interest?.updatedAt = now - 1
    subject.collectedAt = now - 1

    switch subject.typeEnum {
    case .anime, .real:
      guard let eps = eps else {
        break
      }
      let episodes = try modelContext.fetch(
        FetchDescriptor<Episode>(
          predicate: #Predicate<Episode> {
            $0.subjectId == subjectId && $0.type == 0
          },
          sortBy: [
            SortDescriptor<Episode>(\.sort)
          ]
        )
      )
      for (idx, episode) in episodes.enumerated() {
        if idx < eps {
          episode.status = EpisodeCollectionType.collect.rawValue
        } else {
          if episode.status == EpisodeCollectionType.collect.rawValue {
            episode.status = EpisodeCollectionType.none.rawValue
          }
        }
      }
    default:
      break
    }

    try self.commit()
  }

  public func updateSubjectCollection(
    subjectId: Int, type: CollectionType?, rate: Int?, comment: String?, priv: Bool?,
    tags: [String]?, progress: Bool?
  ) throws {
    let subject = try self.fetchOne(
      predicate: #Predicate<Subject> {
        $0.subjectId == subjectId
      }
    )
    guard let subject = subject else {
      return
    }
    let now = Int(Date().timeIntervalSince1970)
    if subject.interest == nil {
      subject.interest = SubjectInterest(
        comment: comment ?? "",
        epStatus: 0,
        volStatus: 0,
        private: priv ?? false,
        rate: rate ?? 0,
        tags: tags ?? [],
        type: type ?? CollectionType.doing,
        updatedAt: now - 1
      )
    } else {
      if let type = type {
        subject.interest?.type = type
        if type == .collect, let progress = progress, progress {
          subject.interest?.epStatus = subject.eps
          subject.interest?.volStatus = subject.volumes
          let eps = try modelContext.fetch(
            FetchDescriptor<Episode>(
              predicate: #Predicate<Episode> {
                $0.subjectId == subjectId && $0.type == 0
              }
            )
          )
          for episode in eps {
            episode.status = EpisodeCollectionType.collect.rawValue
          }
        }
      }
      if let rate = rate {
        subject.interest?.rate = rate
      }
      if let comment = comment {
        subject.interest?.comment = comment
      }
      if let priv = priv {
        subject.interest?.private = priv
      }
      if let tags = tags {
        subject.interest?.tags = tags
      }
    }
    subject.interest?.updatedAt = now - 1
    subject.collectedAt = now - 1
    try self.commit()
  }

  public func updateEpisodeCollection(
    episodeId: Int, type: EpisodeCollectionType, batch: Bool = false
  ) throws {
    let now = Int(Date().timeIntervalSince1970)
    let episode = try self.fetchOne(
      predicate: #Predicate<Episode> {
        $0.episodeId == episodeId
      }
    )
    guard let episode = episode else {
      return
    }
    if batch {
      let subjectId = episode.subjectId
      let sort = episode.sort
      let descriptor = FetchDescriptor<Episode>(
        predicate: #Predicate<Episode> {
          $0.subjectId == subjectId && $0.sort <= sort && $0.type == 0
        }
      )
      let episodes = try modelContext.fetch(descriptor)
      for episode in episodes {
        episode.status = EpisodeCollectionType.collect.rawValue
        episode.collectedAt = now - 1
      }
      episode.subject?.interest?.epStatus = episodes.count
    } else {
      episode.status = type.rawValue
      episode.collectedAt = now - 1
      episode.subject?.interest?.epStatus = (episode.subject?.interest?.epStatus ?? 0) + 1
    }
    episode.subject?.interest?.updatedAt = now - 1
    episode.subject?.collectedAt = now - 1
    try self.commit()
  }

  public func updateCharacterCollection(characterId: Int, collectedAt: Int) throws {
    let character = try self.fetchOne(
      predicate: #Predicate<Character> {
        $0.characterId == characterId
      }
    )
    guard let character = character else {
      return
    }
    character.collectedAt = collectedAt
    try self.commit()
  }

  public func updatePersonCollection(personId: Int, collectedAt: Int) throws {
    let person = try self.fetchOne(
      predicate: #Predicate<Person> {
        $0.personId == personId
      }
    )
    guard let person = person else {
      return
    }
    person.collectedAt = collectedAt
    try self.commit()
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

  public func ensureEpisode(_ item: EpisodeDTO) throws -> Episode {
    let eid = item.id
    let fetched = try self.fetchOne(
      predicate: #Predicate<Episode> {
        $0.episodeId == eid
      })
    if let episode = fetched {
      episode.update(item)
      if let slim = item.subject {
        if let old = episode.subject, old.subjectId == slim.id {
          return episode
        }
        let subject = try self.ensureSubject(slim)
        episode.subject = subject
      } else {
        let subject = try self.getSubject(item.subjectID)
        if let new = subject {
          if let old = episode.subject, old.subjectId == new.subjectId {
            return episode
          }
          episode.subject = new
        }
      }
      return episode
    } else {
      let episode = Episode(item)
      modelContext.insert(episode)
      if let slim = item.subject {
        let subject = try self.ensureSubject(slim)
        episode.subject = subject
      } else {
        let subject = try self.getSubject(item.subjectID)
        episode.subject = subject
      }
      return episode
    }
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

  public func ensureCharacter(_ item: SlimCharacterDTO) throws -> Character {
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

  public func ensurePerson(_ item: SlimPersonDTO) throws -> Person {
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

  public func ensureGroup(_ item: GroupDTO) throws -> Group {
    let gid = item.id
    let fetched = try self.fetchOne(
      predicate: #Predicate<Group> {
        $0.groupId == gid
      })
    if let group = fetched {
      group.update(item)
      return group
    }
    let group = Group(item)
    modelContext.insert(group)
    return group
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

  public func saveEpisode(_ item: EpisodeDTO) throws {
    let _ = try self.ensureEpisode(item)
  }

  public func deleteEpisode(_ episodeId: Int) throws {
    let predicate = #Predicate<Episode> { $0.episodeId == episodeId }
    if let episode = try self.fetchOne(predicate: predicate) {
      modelContext.delete(episode)
    }
  }
}

// MARK: - save subject
extension DatabaseOperator {
  public func saveSubject(_ item: SubjectDTO) throws {
    let _ = try self.ensureSubject(item)
  }

  public func saveSubject(_ item: SlimSubjectDTO) throws {
    let _ = try self.ensureSubject(item)
  }

  public func saveSubjectCharacters(subjectId: Int, items: [SubjectCharacterDTO]) throws {
    let subject = try self.getSubject(subjectId)
    if subject?.characters != items {
      subject?.characters = items
    }
  }

  public func saveSubjectOffprints(subjectId: Int, items: [SubjectRelationDTO]) throws {
    let subject = try self.getSubject(subjectId)
    if subject?.offprints != items {
      subject?.offprints = items
    }
  }

  public func saveSubjectRelations(subjectId: Int, items: [SubjectRelationDTO]) throws {
    let subject = try self.getSubject(subjectId)
    if subject?.relations != items {
      subject?.relations = items
    }
  }

  public func saveSubjectRecs(subjectId: Int, items: [SubjectRecDTO]) throws {
    let subject = try self.getSubject(subjectId)
    if subject?.recs != items {
      subject?.recs = items
    }
  }

  public func saveSubjectCollects(subjectId: Int, items: [SubjectCollectDTO]) throws {
    let subject = try self.getSubject(subjectId)
    if subject?.collects != items {
      subject?.collects = items
    }
  }

  public func saveSubjectReviews(subjectId: Int, items: [SubjectReviewDTO]) throws {
    let subject = try self.getSubject(subjectId)
    if subject?.reviews != items {
      subject?.reviews = items
    }
  }

  public func saveSubjectTopics(subjectId: Int, items: [TopicDTO]) throws {
    let subject = try self.getSubject(subjectId)
    if subject?.topics != items {
      subject?.topics = items
    }
  }

  public func saveSubjectComments(subjectId: Int, items: [SubjectCommentDTO]) throws {
    let subject = try self.getSubject(subjectId)
    if subject?.comments != items {
      subject?.comments = items
    }
  }

  public func saveSubjectIndexes(subjectId: Int, items: [SlimIndexDTO]) throws {
    let subject = try self.getSubject(subjectId)
    if subject?.indexes != items {
      subject?.indexes = items
    }
  }

  public func saveSubjectPositions(subjectId: Int, items: [SubjectPositionDTO]) throws {
    let subject = try self.getSubject(subjectId)
    if subject?.positions != items {
      subject?.positions = items
    }
  }
}

// MARK: - save character
extension DatabaseOperator {
  public func saveCharacter(_ item: CharacterDTO) throws {
    let _ = try self.ensureCharacter(item)
  }

  public func saveCharacter(_ item: SlimCharacterDTO) throws {
    let _ = try self.ensureCharacter(item)
  }

  public func saveCharacterCasts(characterId: Int, items: [CharacterCastDTO]) throws {
    let character = try self.getCharacter(characterId)
    if character?.casts != items {
      character?.casts = items
    }
  }

  public func saveCharacterIndexes(characterId: Int, items: [SlimIndexDTO]) throws {
    let character = try self.getCharacter(characterId)
    if character?.indexes != items {
      character?.indexes = items
    }
  }
}

// MARK: - save person
extension DatabaseOperator {
  public func savePerson(_ item: PersonDTO) throws {
    let _ = try self.ensurePerson(item)
  }

  public func savePerson(_ item: SlimPersonDTO) throws {
    let _ = try self.ensurePerson(item)
  }

  public func savePersonCasts(personId: Int, items: [PersonCastDTO]) throws {
    let person = try self.getPerson(personId)
    if person?.casts != items {
      person?.casts = items
    }
  }

  public func savePersonWorks(personId: Int, items: [PersonWorkDTO]) throws {
    let person = try self.getPerson(personId)
    if person?.works != items {
      person?.works = items
    }
  }

  public func savePersonIndexes(personId: Int, items: [SlimIndexDTO]) throws {
    let person = try self.getPerson(personId)
    if person?.indexes != items {
      person?.indexes = items
    }
  }
}

// MARK: - save group
extension DatabaseOperator {
  public func saveGroup(_ item: GroupDTO) throws {
    let _ = try self.ensureGroup(item)
  }

  public func saveGroupRecentMembers(groupName: String, items: [GroupMemberDTO]) throws {
    let group = try self.getGroup(groupName)
    if group?.recentMembers != items {
      group?.recentMembers = items
    }
  }

  public func saveGroupModerators(groupName: String, items: [GroupMemberDTO]) throws {
    let group = try self.getGroup(groupName)
    if group?.moderators != items {
      group?.moderators = items
    }
  }

  public func saveGroupRecentTopics(groupName: String, items: [TopicDTO]) throws {
    let group = try self.getGroup(groupName)
    if group?.recentTopics != items {
      group?.recentTopics = items
    }
  }
}
