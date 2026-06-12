import Foundation
import OSLog
import SwiftData

@ModelActor
actor DatabaseOperator {}

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

  public func getGroup(_ name: String) throws -> ChiiGroup? {
    let group = try self.fetchOne(
      predicate: #Predicate<ChiiGroup> {
        $0.name == name
      }
    )
    return group
  }

  public func getUserDTO(_ username: String) throws -> UserDTO? {
    try getUser(username).map(UserDTO.init)
  }

  public func getSubjectDTO(_ id: Int) throws -> SubjectDTO? {
    try getSubject(id).map(SubjectDTO.init)
  }

  public func getCharacterDTO(_ id: Int) throws -> CharacterDTO? {
    try getCharacter(id).map(CharacterDTO.init)
  }

  public func getPersonDTO(_ id: Int) throws -> PersonDTO? {
    try getPerson(id).map(PersonDTO.init)
  }

  public func getGroupDTO(_ name: String) throws -> GroupDTO? {
    try getGroup(name).map(GroupDTO.init)
  }

  public func getEpisodeDTO(_ id: Int) throws -> EpisodeDTO? {
    let episode = try self.fetchOne(
      predicate: #Predicate<Episode> {
        $0.episodeId == id
      }
    )
    return episode.map(EpisodeDTO.init)
  }

  public func getSubjectDetailDTO(_ id: Int) throws -> SubjectDetailDTO {
    guard let subject = try getSubject(id) else {
      return SubjectDetailDTO()
    }
    return SubjectDetailDTO(
      positions: subject.positions,
      characters: subject.characters,
      offprints: subject.offprints,
      relations: subject.relations,
      recs: subject.recs,
      collects: subject.collects,
      reviews: subject.reviews,
      topics: subject.topics,
      comments: subject.comments,
      indexes: subject.indexes
    )
  }

  public func getCharacterDetailDTO(_ id: Int) throws -> CharacterDetailDTO {
    guard let character = try getCharacter(id) else {
      return CharacterDetailDTO()
    }
    return CharacterDetailDTO(
      casts: character.casts,
      relations: character.relations,
      indexes: character.indexes
    )
  }

  public func getPersonDetailDTO(_ id: Int) throws -> PersonDetailDTO {
    guard let person = try getPerson(id) else {
      return PersonDetailDTO()
    }
    return PersonDetailDTO(
      casts: person.casts,
      works: person.works,
      relations: person.relations,
      indexes: person.indexes
    )
  }

  public func getGroupDetailDTO(_ name: String) throws -> GroupDetailDTO {
    guard let group = try getGroup(name) else {
      return GroupDetailDTO()
    }
    return GroupDetailDTO(
      moderators: group.moderators,
      recentMembers: group.recentMembers,
      recentTopics: group.recentTopics
    )
  }

  public func fetchCalendarEntries() throws -> [CalendarEntryDTO] {
    let descriptor = FetchDescriptor<BangumiCalendar>(
      sortBy: [SortDescriptor(\.weekday)]
    )
    return try modelContext.fetch(descriptor).map {
      CalendarEntryDTO(weekday: $0.weekday, items: $0.items)
    }
  }

  public func fetchTrendingSubjects(type: SubjectType) throws -> [TrendingSubjectDTO] {
    let typeValue = type.rawValue
    let descriptor = FetchDescriptor<TrendingSubject>(
      predicate: #Predicate<TrendingSubject> { $0.type == typeValue }
    )
    return try modelContext.fetch(descriptor).first?.items ?? []
  }

  public func fetchRakuenSubjectTopicCache(mode: String) throws -> [SubjectTopicDTO] {
    try self.fetchOne(
      predicate: #Predicate<RakuenSubjectTopicCache> { $0.mode == mode }
    )?.items ?? []
  }

  public func fetchRakuenGroupTopicCache(mode: String) throws -> [GroupTopicDTO] {
    try self.fetchOne(
      predicate: #Predicate<RakuenGroupTopicCache> { $0.mode == mode }
    )?.items ?? []
  }

  public func fetchRakuenGroupCache(id: String) throws -> [SlimGroupDTO] {
    try self.fetchOne(
      predicate: #Predicate<RakuenGroupCache> { $0.id == id }
    )?.items ?? []
  }

  public func fetchDrafts(type: String) throws -> [DraftDTO] {
    let descriptor = FetchDescriptor<Draft>(
      predicate: #Predicate<Draft> { $0.type == type },
      sortBy: [SortDescriptor(\.updatedAt, order: .reverse)]
    )
    return try modelContext.fetch(descriptor).map(DraftDTO.init)
  }

  public func getEpisodeIDs(subjectId: Int, sort: Float) throws -> [Int] {
    let descriptor = FetchDescriptor<Episode>(
      predicate: #Predicate<Episode> {
        $0.subjectId == subjectId && $0.sort <= sort
      })
    let episodes = try modelContext.fetch(descriptor)
    return episodes.map { $0.episodeId }
  }

  public func getCollectionTypes(subjectIds: [Int]) throws -> [Int: CollectionType] {
    guard !subjectIds.isEmpty else { return [:] }
    let descriptor = FetchDescriptor<Subject>(
      predicate: #Predicate<Subject> {
        subjectIds.contains($0.subjectId)
      })
    let subjects = try modelContext.fetch(descriptor)
    return subjects.reduce(into: [:]) { $0[$1.subjectId] = $1.ctypeEnum }
  }

  public func fetchLocalSubjects(
    search: String,
    subjectType: SubjectType,
    limit: Int = 20
  ) throws -> [SubjectDTO] {
    let stype = subjectType.rawValue
    var descriptor = FetchDescriptor<Subject>(
      predicate: #Predicate<Subject> {
        (stype == 0 || stype == $0.type)
          && ($0.name.localizedStandardContains(search)
            || $0.alias.localizedStandardContains(search))
      }
    )
    descriptor.fetchLimit = limit
    return try modelContext.fetch(descriptor).map(SubjectDTO.init)
  }

  public func fetchLocalCharacters(search: String, limit: Int = 20) throws -> [CharacterDTO] {
    var descriptor = FetchDescriptor<Character>(
      predicate: #Predicate<Character> {
        $0.name.localizedStandardContains(search)
          || $0.alias.localizedStandardContains(search)
      }
    )
    descriptor.fetchLimit = limit
    return try modelContext.fetch(descriptor).map(CharacterDTO.init)
  }

  public func fetchLocalPersons(search: String, limit: Int = 20) throws -> [PersonDTO] {
    var descriptor = FetchDescriptor<Person>(
      predicate: #Predicate<Person> {
        $0.name.localizedStandardContains(search)
          || $0.alias.localizedStandardContains(search)
      }
    )
    descriptor.fetchLimit = limit
    return try modelContext.fetch(descriptor).map(PersonDTO.init)
  }

  public func fetchCollectionCounts(subjectType: SubjectType) throws -> [CollectionType: Int] {
    let stype = subjectType.rawValue
    var counts: [CollectionType: Int] = [:]
    for type in CollectionType.allTypes() {
      let ctype = type.rawValue
      let descriptor = FetchDescriptor<Subject>(
        predicate: #Predicate<Subject> {
          $0.ctype == ctype && $0.type == stype
        }
      )
      counts[type] = try modelContext.fetchCount(descriptor)
    }
    return counts
  }

  public func fetchCollectionSubjects(
    subjectType: SubjectType,
    collectionType: CollectionType,
    limit: Int,
    offset: Int
  ) throws -> [SubjectDTO] {
    let stype = subjectType.rawValue
    let ctype = collectionType.rawValue
    var descriptor = FetchDescriptor<Subject>(
      predicate: #Predicate<Subject> {
        $0.ctype == ctype && $0.type == stype
      },
      sortBy: [
        SortDescriptor(\.collectedAt, order: .reverse)
      ]
    )
    descriptor.fetchLimit = limit
    descriptor.fetchOffset = offset
    return try modelContext.fetch(descriptor).map(SubjectDTO.init)
  }

  public func fetchEpisodes(
    subjectId: Int,
    main: Bool? = nil,
    uncollectedOnly: Bool = false,
    sortDesc: Bool = false,
    limit: Int? = nil
  ) throws -> [EpisodeDTO] {
    let mainType = EpisodeType.main.rawValue
    let predicate: Predicate<Episode>
    if let main, main, uncollectedOnly {
      predicate = #Predicate<Episode> {
        $0.subjectId == subjectId && $0.type == mainType && $0.status == 0
      }
    } else if let main, main {
      predicate = #Predicate<Episode> {
        $0.subjectId == subjectId && $0.type == mainType
      }
    } else if let main, !main, uncollectedOnly {
      predicate = #Predicate<Episode> {
        $0.subjectId == subjectId && $0.type != mainType && $0.status == 0
      }
    } else if let main, !main {
      predicate = #Predicate<Episode> {
        $0.subjectId == subjectId && $0.type != mainType
      }
    } else {
      predicate = #Predicate<Episode> {
        $0.subjectId == subjectId
      }
    }
    let sortBy =
      sortDesc ? SortDescriptor<Episode>(\.sort, order: .reverse) : SortDescriptor<Episode>(\.sort)
    var descriptor = FetchDescriptor<Episode>(predicate: predicate, sortBy: [sortBy])
    if let limit {
      descriptor.fetchLimit = limit
    }
    return try modelContext.fetch(descriptor).map(EpisodeDTO.init)
  }

  public func fetchDiscEpisodes(subjectId: Int) throws -> [EpisodeDTO] {
    let descriptor = FetchDescriptor<Episode>(
      predicate: #Predicate<Episode> {
        $0.subjectId == subjectId
      },
      sortBy: [SortDescriptor(\.disc), SortDescriptor(\.sort)]
    )
    return try modelContext.fetch(descriptor).map(EpisodeDTO.init)
  }

  public func fetchEpisodeCounts(subjectId: Int) throws -> (main: Int, other: Int) {
    let mainType = EpisodeType.main.rawValue
    let mainDescriptor = FetchDescriptor<Episode>(
      predicate: #Predicate<Episode> {
        $0.subjectId == subjectId && $0.type == mainType
      }
    )
    let otherDescriptor = FetchDescriptor<Episode>(
      predicate: #Predicate<Episode> {
        $0.subjectId == subjectId && $0.type != mainType
      }
    )
    return (
      main: try modelContext.fetchCount(mainDescriptor),
      other: try modelContext.fetchCount(otherDescriptor)
    )
  }

  public func fetchProgressSubject(
    subjectId: Int,
    episodeWindowSize: Int = 7
  ) throws -> ProgressSubjectDTO? {
    guard let subject = try getSubject(subjectId) else {
      return nil
    }

    let episodes: [EpisodeDTO]
    switch subject.typeEnum {
    case .anime, .real:
      episodes = try fetchProgressEpisodes(
        subjectId: subjectId,
        windowSize: episodeWindowSize
      )
    default:
      episodes = []
    }

    return ProgressSubjectDTO(
      subject: SubjectDTO(subject),
      episodes: episodes
    )
  }

  private func fetchProgressEpisodes(subjectId: Int, windowSize: Int) throws -> [EpisodeDTO] {
    let windowSize = max(1, windowSize)
    let mainType = EpisodeType.main.rawValue
    var nextDescriptor = FetchDescriptor<Episode>(
      predicate: #Predicate<Episode> {
        $0.subjectId == subjectId && $0.type == mainType && $0.status == 0
      },
      sortBy: [
        SortDescriptor<Episode>(\.sort, order: .forward)
      ]
    )
    nextDescriptor.fetchLimit = 1

    guard let nextEpisode = try modelContext.fetch(nextDescriptor).first else {
      var suffixDescriptor = FetchDescriptor<Episode>(
        predicate: #Predicate<Episode> { $0.subjectId == subjectId && $0.type == mainType },
        sortBy: [
          SortDescriptor<Episode>(\.sort, order: .reverse)
        ]
      )
      suffixDescriptor.fetchLimit = windowSize
      return try modelContext.fetch(suffixDescriptor)
        .reversed()
        .map(EpisodeDTO.init)
    }

    let halfBefore = (windowSize - 1) / 2
    let halfAfter = windowSize - halfBefore - 1
    let nextSort = nextEpisode.sort

    var beforeDescriptor = FetchDescriptor<Episode>(
      predicate: #Predicate<Episode> {
        $0.subjectId == subjectId && $0.type == mainType && $0.sort < nextSort
      },
      sortBy: [
        SortDescriptor<Episode>(\.sort, order: .reverse)
      ]
    )
    beforeDescriptor.fetchLimit = max(windowSize - 1, 0)

    var afterDescriptor = FetchDescriptor<Episode>(
      predicate: #Predicate<Episode> {
        $0.subjectId == subjectId && $0.type == mainType && $0.sort > nextSort
      },
      sortBy: [
        SortDescriptor<Episode>(\.sort, order: .forward)
      ]
    )
    afterDescriptor.fetchLimit = max(windowSize - 1, 0)

    let before = try modelContext.fetch(beforeDescriptor).reversed()
    let after = try modelContext.fetch(afterDescriptor)

    let beforeCount: Int
    let afterCount: Int
    if before.count < halfBefore {
      beforeCount = before.count
      afterCount = min(after.count, windowSize - beforeCount - 1)
    } else if after.count < halfAfter {
      afterCount = after.count
      beforeCount = min(before.count, windowSize - afterCount - 1)
    } else {
      beforeCount = halfBefore
      afterCount = halfAfter
    }

    return (before.suffix(beforeCount) + [nextEpisode] + after.prefix(afterCount))
      .map(EpisodeDTO.init)
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

  public func fetchCollectedSubjectSearchable(
    limit: Int = 50,
    offset: Int = 0
  ) throws -> PagedDTO<SearchableItem> {
    var descriptor = FetchDescriptor<Subject>(
      predicate: #Predicate<Subject> {
        $0.ctype != 0
      }
    )
    let total = try modelContext.fetchCount(descriptor)
    descriptor.fetchLimit = limit
    descriptor.fetchOffset = offset
    let items = try modelContext.fetch(descriptor)
    return PagedDTO(
      data: items.map { $0.searchable() },
      total: total
    )
  }

  private func makeSubjectDescriptor(
    subjectType: SubjectType?,
    collectionType: CollectionType?,
    sortBy: [SortDescriptor<Subject>] = []
  ) -> FetchDescriptor<Subject> {
    if let stype = subjectType, let ctype = collectionType {
      let stypeRaw = stype.rawValue
      let ctypeRaw = ctype.rawValue
      return FetchDescriptor<Subject>(
        predicate: #Predicate<Subject> {
          $0.type == stypeRaw && $0.ctype == ctypeRaw
        },
        sortBy: sortBy
      )
    }
    if let stype = subjectType {
      let stypeRaw = stype.rawValue
      return FetchDescriptor<Subject>(
        predicate: #Predicate<Subject> {
          $0.type == stypeRaw && $0.ctype != 0
        },
        sortBy: sortBy
      )
    }
    if let ctype = collectionType {
      let ctypeRaw = ctype.rawValue
      return FetchDescriptor<Subject>(
        predicate: #Predicate<Subject> {
          $0.ctype == ctypeRaw
        },
        sortBy: sortBy
      )
    }
    return FetchDescriptor<Subject>(
      predicate: #Predicate<Subject> {
        $0.ctype != 0
      },
      sortBy: sortBy
    )
  }

  public func countSubjects(
    subjectType: SubjectType?,
    collectionType: CollectionType?
  ) throws -> Int {
    let descriptor = makeSubjectDescriptor(
      subjectType: subjectType,
      collectionType: collectionType
    )
    return try modelContext.fetchCount(descriptor)
  }

  public func fetchProgressCounts() throws -> [SubjectType: Int] {
    var counts: [SubjectType: Int] = [:]
    let doingType = CollectionType.doing.rawValue
    for type in SubjectType.progressTypes {
      let tvalue = type.rawValue
      let desc = FetchDescriptor<Subject>(
        predicate: #Predicate<Subject> {
          (tvalue == 0 || $0.type == tvalue) && $0.ctype == doingType
        })
      counts[type] = try modelContext.fetchCount(desc)
    }
    return counts
  }

  public func fetchProgressSubjectIds(
    progressTab: SubjectType,
    progressSortMode: ProgressSortMode,
    search: String
  ) throws -> [Int] {
    let stype = progressTab.rawValue
    let doingType = CollectionType.doing.rawValue
    let descriptor = FetchDescriptor<Subject>(
      predicate: #Predicate<Subject> {
        (stype == 0 || $0.type == stype) && $0.ctype == doingType
          && (search == "" || $0.name.localizedStandardContains(search)
            || $0.alias.localizedStandardContains(search))
      },
      sortBy: [
        SortDescriptor(\.collectedAt, order: .reverse)
      ])

    let subjects = try modelContext.fetch(descriptor)

    switch progressSortMode {
    case .airTime:
      let subjectIds = subjects.map(\.subjectId)
      if subjectIds.isEmpty {
        return []
      }
      let mainType = EpisodeType.main.rawValue
      let episodeDescriptor = FetchDescriptor<Episode>(
        predicate: #Predicate<Episode> {
          subjectIds.contains($0.subjectId) && $0.type == mainType && $0.status == 0
        },
        sortBy: [
          SortDescriptor<Episode>(\.subjectId, order: .forward),
          SortDescriptor<Episode>(\.sort, order: .forward),
        ]
      )
      let episodes = try modelContext.fetch(episodeDescriptor)
      var nextEpisodes: [Int: Episode] = [:]
      for episode in episodes where nextEpisodes[episode.subjectId] == nil {
        nextEpisodes[episode.subjectId] = episode
      }

      func nextEpisodeDays(subject: Subject, episode: Episode?) -> Int {
        guard subject.typeEnum == .anime || subject.typeEnum == .real else {
          return Int.max
        }
        guard let episode else {
          return Int.max
        }
        if episode.air.timeIntervalSince1970 == 0 {
          return Int.max - 1
        }
        let calendar = Calendar.current
        let now = Date()
        let nowDate = calendar.startOfDay(for: now)
        let airDate = calendar.startOfDay(for: episode.air)
        let components = calendar.dateComponents([.day], from: nowDate, to: airDate)
        return components.day ?? Int.max
      }

      var daysMap: [Int: Int] = [:]
      for subject in subjects {
        daysMap[subject.subjectId] = nextEpisodeDays(
          subject: subject,
          episode: nextEpisodes[subject.subjectId]
        )
      }

      return subjects.sorted { subject1, subject2 in
        let days1 = daysMap[subject1.subjectId] ?? Int.max
        let days2 = daysMap[subject2.subjectId] ?? Int.max
        return Subject.compareDays(days1, days2, subject1, subject2)
      }.map(\.subjectId)
    case .collectedAt:
      return subjects.map(\.subjectId)
    }
  }

  public func exportSubjectsToCSV(
    subjectType: SubjectType?,
    collectionType: CollectionType?,
    fields: Set<ExportableField>,
    coverSize: CoverExportSize = .r400
  ) throws -> URL? {
    let descriptor = makeSubjectDescriptor(
      subjectType: subjectType,
      collectionType: collectionType,
      sortBy: [SortDescriptor(\.collectedAt, order: .reverse)]
    )
    let subjects = try modelContext.fetch(descriptor)
    return ExportManager.exportSubjects(
      subjects: subjects,
      fields: fields,
      coverSize: coverSize
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
    subject.collectedAt = now - 1
    if let ctype = type {
      subject.ctype = ctype.rawValue
    }
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
  }
}

// MARK: - ensure
extension DatabaseOperator {
  public func ensureUser(_ item: UserDTO) throws -> (User, Bool) {
    let uid = item.id
    let fetched = try self.fetchOne(
      predicate: #Predicate<User> {
        $0.userId == uid
      })
    if let user = fetched {
      user.update(item)
      return (user, false)
    }
    let user = User(item)
    modelContext.insert(user)
    return (user, true)
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

  public func ensureSubject(_ item: SubjectDTO) throws -> (Subject, Bool) {
    let sid = item.id
    let fetched = try self.fetchOne(
      predicate: #Predicate<Subject> {
        $0.subjectId == sid
      })
    if let subject = fetched {
      subject.update(item)
      return (subject, false)
    }
    let subject = Subject(item)
    modelContext.insert(subject)
    return (subject, true)
  }

  public func ensureSubject(_ item: SlimSubjectDTO) throws -> (Subject, Bool) {
    let sid = item.id
    let fetched = try self.fetchOne(
      predicate: #Predicate<Subject> {
        $0.subjectId == sid
      })
    if let subject = fetched {
      subject.update(item)
      return (subject, false)
    }
    let subject = Subject(item)
    modelContext.insert(subject)
    return (subject, true)
  }

  public func ensureEpisode(_ item: EpisodeDTO) throws -> (Episode, Bool) {
    let eid = item.id
    let fetched = try self.fetchOne(
      predicate: #Predicate<Episode> {
        $0.episodeId == eid
      })
    if let episode = fetched {
      episode.update(item)
      if let slim = item.subject {
        if let old = episode.subject, old.subjectId == slim.id {
          return (episode, false)
        }
        let (subject, _) = try self.ensureSubject(slim)
        episode.subject = subject
      } else {
        let subject = try self.getSubject(item.subjectID)
        if let new = subject {
          if let old = episode.subject, old.subjectId == new.subjectId {
            return (episode, false)
          }
          episode.subject = new
        }
      }
      return (episode, false)
    } else {
      let episode = Episode(item)
      modelContext.insert(episode)
      if let slim = item.subject {
        let (subject, _) = try self.ensureSubject(slim)
        episode.subject = subject
      } else {
        let subject = try self.getSubject(item.subjectID)
        episode.subject = subject
      }
      return (episode, true)
    }
  }

  public func ensureCharacter(_ item: CharacterDTO) throws -> (Character, Bool) {
    let cid = item.id
    let fetched = try self.fetchOne(
      predicate: #Predicate<Character> {
        $0.characterId == cid
      })
    if let character = fetched {
      character.update(item)
      return (character, false)
    }
    let character = Character(item)
    modelContext.insert(character)
    return (character, true)
  }

  public func ensureCharacter(_ item: SlimCharacterDTO) throws -> (Character, Bool) {
    let cid = item.id
    let fetched = try self.fetchOne(
      predicate: #Predicate<Character> {
        $0.characterId == cid
      })
    if let character = fetched {
      character.update(item)
      return (character, false)
    }
    let character = Character(item)
    modelContext.insert(character)
    return (character, true)
  }

  public func ensurePerson(_ item: PersonDTO) throws -> (Person, Bool) {
    let pid = item.id
    let fetched = try self.fetchOne(
      predicate: #Predicate<Person> {
        $0.personId == pid
      })
    if let person = fetched {
      person.update(item)
      return (person, false)
    }
    let person = Person(item)
    modelContext.insert(person)
    return (person, true)
  }

  public func ensurePerson(_ item: SlimPersonDTO) throws -> (Person, Bool) {
    let pid = item.id
    let fetched = try self.fetchOne(
      predicate: #Predicate<Person> {
        $0.personId == pid
      })
    if let person = fetched {
      person.update(item)
      return (person, false)
    }
    let person = Person(item)
    modelContext.insert(person)
    return (person, true)
  }

  public func ensureGroup(_ item: GroupDTO) throws -> (ChiiGroup, Bool) {
    let gid = item.id
    let fetched = try self.fetchOne(
      predicate: #Predicate<ChiiGroup> {
        $0.groupId == gid
      })
    if let group = fetched {
      group.update(item)
      return (group, false)
    }
    let group = ChiiGroup(item)
    modelContext.insert(group)
    return (group, true)
  }
}

// MARK: - save
extension DatabaseOperator {
  @discardableResult
  public func saveUser(_ item: UserDTO) throws -> Bool {
    let (_, created) = try self.ensureUser(item)
    return created
  }

  public func saveCalendarItem(weekday: Int, items: [BangumiCalendarItemDTO]) throws {
    _ = try self.ensureCalendarItem(weekday, items: items)
  }

  public func saveTrendingSubjects(type: Int, items: [TrendingSubjectDTO]) throws {
    _ = try self.ensureTrendingSubject(type, items: items)
  }

  @discardableResult
  public func saveEpisode(_ item: EpisodeDTO) throws -> Bool {
    let (_, created) = try self.ensureEpisode(item)
    return created
  }

  public func saveEpisodes(subjectId: Int, items: [EpisodeDTO]) throws {
    guard !items.isEmpty else { return }
    let descriptor = FetchDescriptor<Episode>(
      predicate: #Predicate<Episode> {
        $0.subjectId == subjectId
      }
    )
    let existing = try modelContext.fetch(descriptor)
    var existingMap = Dictionary(uniqueKeysWithValues: existing.map { ($0.episodeId, $0) })
    var subjectRef = try getSubject(subjectId)
    if subjectRef == nil, let slim = items.first?.subject {
      subjectRef = try ensureSubject(slim).0
    }

    for item in items {
      if let episode = existingMap[item.id] {
        episode.update(item)
        if episode.subject == nil {
          episode.subject = subjectRef
        }
      } else {
        let episode = Episode(item)
        episode.subject = subjectRef
        modelContext.insert(episode)
        existingMap[item.id] = episode
      }
    }
  }

  public func deleteEpisode(_ episodeId: Int) throws {
    let predicate = #Predicate<Episode> { $0.episodeId == episodeId }
    if let episode = try self.fetchOne(predicate: predicate) {
      modelContext.delete(episode)
    }
  }

  public func deleteEpisodesNotIn(subjectId: Int, episodeIds: Set<Int>) throws {
    let descriptor = FetchDescriptor<Episode>(
      predicate: #Predicate<Episode> {
        $0.subjectId == subjectId
      }
    )
    let episodes = try modelContext.fetch(descriptor)
    for episode in episodes where !episodeIds.contains(episode.episodeId) {
      modelContext.delete(episode)
    }
  }
}

// MARK: - save subject
extension DatabaseOperator {
  @discardableResult
  public func saveSubject(_ item: SubjectDTO) throws -> Bool {
    let (_, created) = try self.ensureSubject(item)
    return created
  }

  @discardableResult
  public func saveSubject(_ item: SlimSubjectDTO) throws -> Bool {
    let (_, created) = try self.ensureSubject(item)
    return created
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

  public func saveSubjectDetails(
    subjectId: Int,
    characters: [SubjectCharacterDTO]?,
    offprints: [SubjectRelationDTO]?,
    relations: [SubjectRelationDTO]?,
    recs: [SubjectRecDTO]?,
    collects: [SubjectCollectDTO]?,
    reviews: [SubjectReviewDTO]?,
    topics: [TopicDTO]?,
    comments: [SubjectCommentDTO]?,
    indexes: [SlimIndexDTO]?
  ) throws {
    let subject = try self.getSubject(subjectId)
    guard let subject else {
      return
    }
    if let characters, subject.characters != characters {
      subject.characters = characters
    }
    if let offprints, subject.offprints != offprints {
      subject.offprints = offprints
    }
    if let relations, subject.relations != relations {
      subject.relations = relations
    }
    if let recs, subject.recs != recs {
      subject.recs = recs
    }
    if let collects, subject.collects != collects {
      subject.collects = collects
    }
    if let reviews, subject.reviews != reviews {
      subject.reviews = reviews
    }
    if let topics, subject.topics != topics {
      subject.topics = topics
    }
    if let comments, subject.comments != comments {
      subject.comments = comments
    }
    if let indexes, subject.indexes != indexes {
      subject.indexes = indexes
    }
  }
}

// MARK: - save character
extension DatabaseOperator {
  @discardableResult
  public func saveCharacter(_ item: CharacterDTO) throws -> Bool {
    let (_, created) = try self.ensureCharacter(item)
    return created
  }

  @discardableResult
  public func saveCharacter(_ item: SlimCharacterDTO) throws -> Bool {
    let (_, created) = try self.ensureCharacter(item)
    return created
  }

  public func saveCharacterCasts(characterId: Int, items: [CharacterCastDTO]) throws {
    let character = try self.getCharacter(characterId)
    if character?.casts != items {
      character?.casts = items
    }
  }

  public func saveCharacterRelations(characterId: Int, items: [CharacterRelationDTO]) throws {
    let character = try self.getCharacter(characterId)
    if character?.relations != items {
      character?.relations = items
    }
  }

  public func saveCharacterIndexes(characterId: Int, items: [SlimIndexDTO]) throws {
    let character = try self.getCharacter(characterId)
    if character?.indexes != items {
      character?.indexes = items
    }
  }

  public func saveCharacterDetails(
    characterId: Int,
    casts: [CharacterCastDTO]?,
    relations: [CharacterRelationDTO]?,
    indexes: [SlimIndexDTO]?
  ) throws {
    let character = try self.getCharacter(characterId)
    guard let character else {
      return
    }
    if let casts, character.casts != casts {
      character.casts = casts
    }
    if let relations, character.relations != relations {
      character.relations = relations
    }
    if let indexes, character.indexes != indexes {
      character.indexes = indexes
    }
  }
}

// MARK: - save person
extension DatabaseOperator {
  @discardableResult
  public func savePerson(_ item: PersonDTO) throws -> Bool {
    let (_, created) = try self.ensurePerson(item)
    return created
  }

  @discardableResult
  public func savePerson(_ item: SlimPersonDTO) throws -> Bool {
    let (_, created) = try self.ensurePerson(item)
    return created
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

  public func savePersonRelations(personId: Int, items: [PersonRelationDTO]) throws {
    let person = try self.getPerson(personId)
    if person?.relations != items {
      person?.relations = items
    }
  }

  public func savePersonIndexes(personId: Int, items: [SlimIndexDTO]) throws {
    let person = try self.getPerson(personId)
    if person?.indexes != items {
      person?.indexes = items
    }
  }

  public func savePersonDetails(
    personId: Int,
    casts: [PersonCastDTO]?,
    works: [PersonWorkDTO]?,
    relations: [PersonRelationDTO]?,
    indexes: [SlimIndexDTO]?
  ) throws {
    let person = try self.getPerson(personId)
    guard let person else {
      return
    }
    if let casts, person.casts != casts {
      person.casts = casts
    }
    if let works, person.works != works {
      person.works = works
    }
    if let relations, person.relations != relations {
      person.relations = relations
    }
    if let indexes, person.indexes != indexes {
      person.indexes = indexes
    }
  }
}

// MARK: - save group
extension DatabaseOperator {
  @discardableResult
  public func saveGroup(_ item: GroupDTO) throws -> Bool {
    let (_, created) = try self.ensureGroup(item)
    return created
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

  public func saveGroupDetails(
    groupName: String,
    recentMembers: [GroupMemberDTO]?,
    moderators: [GroupMemberDTO]?,
    recentTopics: [TopicDTO]?
  ) throws {
    let group = try self.getGroup(groupName)
    guard let group else {
      return
    }
    if let recentMembers, group.recentMembers != recentMembers {
      group.recentMembers = recentMembers
    }
    if let moderators, group.moderators != moderators {
      group.moderators = moderators
    }
    if let recentTopics, group.recentTopics != recentTopics {
      group.recentTopics = recentTopics
    }
  }
}

// MARK: - Draft & Cache
extension DatabaseOperator {
  public func saveDraft(type: String, content: String, id: PersistentIdentifier? = nil) throws
    -> PersistentIdentifier
  {
    if let id = id {
      let fetched = try self.fetchOne(
        predicate: #Predicate<Draft> { $0.persistentModelID == id }
      )
      if let draft = fetched {
        draft.update(content: content)
        return draft.persistentModelID
      }
    }

    let fetched = try self.fetchOne(
      predicate: #Predicate<Draft> {
        $0.type == type && $0.content == content
      })
    if let draft = fetched {
      return draft.persistentModelID
    }

    let draft = Draft(type: type, content: content)
    modelContext.insert(draft)
    // A newly inserted SwiftData model can have a temporary identifier until it is saved.
    // Return only after persisting so callers can update the same draft on the next save.
    try modelContext.save()
    return draft.persistentModelID
  }

  public func deleteDraft(id: PersistentIdentifier) {
    do {
      let fetched = try self.fetchOne(
        predicate: #Predicate<Draft> { $0.persistentModelID == id }
      )
      if let draft = fetched {
        modelContext.delete(draft)
      }
    } catch {
      Logger.app.error("Failed to delete draft: \(error)")
    }
  }

  public func clearDrafts() throws {
    try modelContext.delete(model: Draft.self)
  }

  public func saveRakuenSubjectTopicCache(mode: String, items: [SubjectTopicDTO]) throws {
    let fetched = try self.fetchOne(
      predicate: #Predicate<RakuenSubjectTopicCache> { $0.mode == mode }
    )
    if let cache = fetched {
      cache.items = items
      cache.updatedAt = Date()
    } else {
      let cache = RakuenSubjectTopicCache(mode: mode, items: items)
      modelContext.insert(cache)
    }
  }

  public func saveRakuenGroupTopicCache(mode: String, items: [GroupTopicDTO]) throws {
    let fetched = try self.fetchOne(
      predicate: #Predicate<RakuenGroupTopicCache> { $0.mode == mode }
    )
    if let cache = fetched {
      cache.items = items
      cache.updatedAt = Date()
    } else {
      let cache = RakuenGroupTopicCache(mode: mode, items: items)
      modelContext.insert(cache)
    }
  }

  public func saveRakuenGroupCache(id: String, items: [SlimGroupDTO]) throws {
    let fetched = try self.fetchOne(
      predicate: #Predicate<RakuenGroupCache> { $0.id == id }
    )
    if let cache = fetched {
      cache.items = items
      cache.updatedAt = Date()
    } else {
      let cache = RakuenGroupCache(id: id, items: items)
      modelContext.insert(cache)
    }
  }

  public func togglePinRakuenGroupCache(group: SlimGroupDTO) throws {
    let fetched = try self.fetchOne(
      predicate: #Predicate<RakuenGroupCache> { $0.id == "pin" }
    )
    if let cache = fetched {
      if cache.items.contains(where: { $0.id == group.id }) {
        cache.items.removeAll { $0.id == group.id }
      } else {
        cache.items.insert(group, at: 0)
      }
      cache.updatedAt = Date()
    } else {
      let cache = RakuenGroupCache(id: "pin", items: [group])
      modelContext.insert(cache)
    }
  }

  public func updateGroupJoinStatus(name: String, joinedAt: Int) throws {
    let group = try self.getGroup(name)
    if let group = group {
      group.joinedAt = joinedAt
    }
  }
}
