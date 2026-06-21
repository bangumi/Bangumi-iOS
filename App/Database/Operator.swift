import Foundation
import GRDB
import OSLog

actor DatabaseOperator {
  private let database: DatabaseQueue

  init(database: DatabaseQueue) {
    self.database = database
  }
}

// MARK: - basic
extension DatabaseOperator {
  public func clearSubjectInterest() throws {
    try database.write { db in
      try db.execute(sql: "UPDATE subjects SET ctype = 0, collected_at = 0, interest_data = NULL")
    }
  }

  public func clearEpisodeCollection() throws {
    try database.write { db in
      try db.execute(sql: "UPDATE episodes SET status = 0, collected_at = 0")
    }
  }

  public func clearPersonCollection() throws {
    try database.write { db in
      try db.execute(sql: "UPDATE persons SET collected_at = 0")
    }
  }

  public func clearCharacterCollection() throws {
    try database.write { db in
      try db.execute(sql: "UPDATE characters SET collected_at = 0")
    }
  }
}

// MARK: - fetch
extension DatabaseOperator {
  public func getUser(_ username: String) throws -> User? {
    try database.read { db in
      try fetchUser(in: db, username: username)
    }
  }

  public func getSubject(_ id: Int) throws -> Subject? {
    try database.read { db in
      try fetchSubject(in: db, id: id)
    }
  }

  public func getCharacter(_ id: Int) throws -> Character? {
    try database.read { db in
      try fetchCharacter(in: db, id: id)
    }
  }

  public func getPerson(_ id: Int) throws -> Person? {
    try database.read { db in
      try fetchPerson(in: db, id: id)
    }
  }

  public func getGroup(_ name: String) throws -> ChiiGroup? {
    try database.read { db in
      try fetchGroup(in: db, name: name)
    }
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
    try database.read { db in
      try fetchEpisode(in: db, id: id, includeSubject: true).map(EpisodeDTO.init)
    }
  }

  public func getSubjectDetailDTO(_ id: Int) throws -> SubjectDetailDTO {
    try database.read { db in
      guard try fetchSubject(in: db, id: id) != nil else {
        return SubjectDetailDTO()
      }
      let detail = try fetchSubjectDetail(in: db, subjectId: id)
      return SubjectDetailDTO(
        positions: detail?.positions ?? [],
        characters: detail?.characters ?? [],
        offprints: detail?.offprints ?? [],
        relations: detail?.relations ?? [],
        recs: detail?.recs ?? [],
        collects: detail?.collects ?? [],
        reviews: detail?.reviews ?? [],
        topics: detail?.topics ?? [],
        comments: detail?.comments ?? [],
        indexes: detail?.indexes ?? []
      )
    }
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
    try database.read { db in
      try Row.fetchAll(
        db,
        sql: "SELECT * FROM calendar_entries ORDER BY weekday"
      ).map {
        let calendar = BangumiCalendar(row: $0)
        return CalendarEntryDTO(weekday: calendar.weekday, items: calendar.items)
      }
    }
  }

  public func fetchTrendingSubjects(type: SubjectType) throws -> [TrendingSubjectDTO] {
    try database.read { db in
      try Row.fetchOne(
        db,
        sql: "SELECT * FROM trending_subjects WHERE type = ?",
        arguments: [type.rawValue]
      ).map { TrendingSubject(row: $0).items } ?? []
    }
  }

  public func fetchRakuenSubjectTopicCache(mode: String) throws -> [SubjectTopicDTO] {
    try database.read { db in
      try Row.fetchOne(
        db,
        sql: "SELECT * FROM rakuen_subject_topic_caches WHERE mode = ?",
        arguments: [mode]
      ).map { RakuenSubjectTopicCache(row: $0).items } ?? []
    }
  }

  public func fetchRakuenGroupTopicCache(mode: String) throws -> [GroupTopicDTO] {
    try database.read { db in
      try Row.fetchOne(
        db,
        sql: "SELECT * FROM rakuen_group_topic_caches WHERE mode = ?",
        arguments: [mode]
      ).map { RakuenGroupTopicCache(row: $0).items } ?? []
    }
  }

  public func fetchRakuenGroupCache(id: String) throws -> [SlimGroupDTO] {
    try database.read { db in
      try Row.fetchOne(
        db,
        sql: "SELECT * FROM rakuen_group_caches WHERE id = ?",
        arguments: [id]
      ).map { RakuenGroupCache(row: $0).items } ?? []
    }
  }

  public func fetchDrafts(type: String) throws -> [DraftDTO] {
    try database.read { db in
      try Row.fetchAll(
        db,
        sql: "SELECT * FROM drafts WHERE type = ? ORDER BY updated_at DESC",
        arguments: [type]
      ).map { DraftDTO(Draft(row: $0)) }
    }
  }

  public func getEpisodeIDs(subjectId: Int, sort: Float) throws -> [Int] {
    try database.read { db in
      try Int.fetchAll(
        db,
        sql: "SELECT episode_id FROM episodes WHERE subject_id = ? AND sort <= ?",
        arguments: [subjectId, sort]
      )
    }
  }

  public func getCollectionTypes(subjectIds: [Int]) throws -> [Int: CollectionType] {
    try database.read { db in
      try collectionTypes(in: db, subjectIds: subjectIds)
    }
  }

  public func characterCollectionStatuses(characterIds: [Int]) throws -> [Int: Bool] {
    try database.read { db in
      guard !characterIds.isEmpty else { return [:] }
      let rows = try Row.fetchAll(
        db,
        sql: """
          SELECT character_id, collected_at FROM characters
          WHERE character_id IN (\(placeholders(characterIds.count)))
          """,
        arguments: StatementArguments(characterIds)
      )
      return rows.reduce(into: [:]) { result, row in
        let id: Int = row["character_id"]
        let collectedAt: Int = row["collected_at"]
        result[id] = collectedAt > 0
      }
    }
  }

  public func personCollectionStatuses(personIds: [Int]) throws -> [Int: Bool] {
    try database.read { db in
      guard !personIds.isEmpty else { return [:] }
      let rows = try Row.fetchAll(
        db,
        sql: """
          SELECT person_id, collected_at FROM persons
          WHERE person_id IN (\(placeholders(personIds.count)))
          """,
        arguments: StatementArguments(personIds)
      )
      return rows.reduce(into: [:]) { result, row in
        let id: Int = row["person_id"]
        let collectedAt: Int = row["collected_at"]
        result[id] = collectedAt > 0
      }
    }
  }

  public func makeSubjectListItems(_ subjects: [SlimSubjectDTO]) throws -> [SubjectListItemDTO] {
    let collectionTypes = try getCollectionTypes(subjectIds: subjects.map(\.id))
    return subjects.map { subject in
      SubjectListItemDTO(
        subject: subject,
        collectionType: collectionTypes[subject.id] ?? .none
      )
    }
  }

  public func fetchLocalSubjects(
    search: String,
    subjectType: SubjectType,
    limit: Int = 20
  ) throws -> [SubjectDTO] {
    try database.read { db in
      let pattern = likePattern(search)
      let rows = try Row.fetchAll(
        db,
        sql: """
          SELECT * FROM subjects
          WHERE (? = 0 OR type = ?)
            AND (name LIKE ? COLLATE NOCASE OR alias LIKE ? COLLATE NOCASE)
          LIMIT ?
          """,
        arguments: [subjectType.rawValue, subjectType.rawValue, pattern, pattern, limit]
      )
      return rows.map { SubjectDTO(Subject(row: $0)) }
    }
  }

  public func fetchLocalCharacters(search: String, limit: Int = 20) throws -> [CharacterDTO] {
    try database.read { db in
      let pattern = likePattern(search)
      return try Row.fetchAll(
        db,
        sql: """
          SELECT * FROM characters
          WHERE name LIKE ? COLLATE NOCASE OR alias LIKE ? COLLATE NOCASE
          LIMIT ?
          """,
        arguments: [pattern, pattern, limit]
      ).map { CharacterDTO(Character(row: $0)) }
    }
  }

  public func fetchLocalPersons(search: String, limit: Int = 20) throws -> [PersonDTO] {
    try database.read { db in
      let pattern = likePattern(search)
      return try Row.fetchAll(
        db,
        sql: """
          SELECT * FROM persons
          WHERE name LIKE ? COLLATE NOCASE OR alias LIKE ? COLLATE NOCASE
          LIMIT ?
          """,
        arguments: [pattern, pattern, limit]
      ).map { PersonDTO(Person(row: $0)) }
    }
  }

  public func fetchCollectionCounts(subjectType: SubjectType) throws -> [CollectionType: Int] {
    try database.read { db in
      var counts: [CollectionType: Int] = [:]
      for type in CollectionType.allTypes() {
        counts[type] =
          try Int.fetchOne(
            db,
            sql: "SELECT COUNT(*) FROM subjects WHERE ctype = ? AND type = ?",
            arguments: [type.rawValue, subjectType.rawValue]
          ) ?? 0
      }
      return counts
    }
  }

  public func fetchCollectionSubjects(
    subjectType: SubjectType,
    collectionType: CollectionType,
    limit: Int,
    offset: Int
  ) throws -> [SubjectDTO] {
    try database.read { db in
      try fetchSubjects(
        in: db,
        whereSQL: "ctype = ? AND type = ?",
        arguments: [collectionType.rawValue, subjectType.rawValue],
        orderSQL: "collected_at DESC",
        limit: limit,
        offset: offset
      ).map(SubjectDTO.init)
    }
  }

  public func fetchEpisodes(
    subjectId: Int,
    main: Bool? = nil,
    uncollectedOnly: Bool = false,
    sortDesc: Bool = false,
    limit: Int? = nil
  ) throws -> [EpisodeDTO] {
    try database.read { db in
      var clauses = ["subject_id = ?"]
      var arguments: StatementArguments = [subjectId]
      if let main {
        if main {
          clauses.append("type = ?")
          arguments += [EpisodeType.main.rawValue]
        } else {
          clauses.append("type != ?")
          arguments += [EpisodeType.main.rawValue]
        }
      }
      if uncollectedOnly {
        clauses.append("status = 0")
      }
      var sql = """
        SELECT * FROM episodes
        WHERE \(clauses.joined(separator: " AND "))
        ORDER BY sort \(sortDesc ? "DESC" : "ASC")
        """
      if let limit {
        sql += " LIMIT ?"
        arguments += [limit]
      }
      return try Row.fetchAll(db, sql: sql, arguments: arguments)
        .map { EpisodeDTO(Episode(row: $0)) }
    }
  }

  public func fetchDiscEpisodes(subjectId: Int) throws -> [EpisodeDTO] {
    try database.read { db in
      try Row.fetchAll(
        db,
        sql: "SELECT * FROM episodes WHERE subject_id = ? ORDER BY disc ASC, sort ASC",
        arguments: [subjectId]
      ).map { EpisodeDTO(Episode(row: $0)) }
    }
  }

  public func fetchEpisodeCounts(subjectId: Int) throws -> (main: Int, other: Int) {
    try database.read { db in
      let main =
        try Int.fetchOne(
          db,
          sql: "SELECT COUNT(*) FROM episodes WHERE subject_id = ? AND type = ?",
          arguments: [subjectId, EpisodeType.main.rawValue]
        ) ?? 0
      let other =
        try Int.fetchOne(
          db,
          sql: "SELECT COUNT(*) FROM episodes WHERE subject_id = ? AND type != ?",
          arguments: [subjectId, EpisodeType.main.rawValue]
        ) ?? 0
      return (main: main, other: other)
    }
  }

  public func fetchProgressSubject(
    subjectId: Int,
    episodeWindowSize: Int = 7
  ) throws -> ProgressSubjectDTO? {
    try database.read { db in
      guard let subject = try fetchSubject(in: db, id: subjectId) else {
        return nil
      }
      return try makeProgressSubject(in: db, subject, episodeWindowSize: episodeWindowSize)
    }
  }

  public func fetchProgressSubject(
    subjectId: Int,
    progressTab: SubjectType,
    search: String,
    episodeWindowSize: Int = 7
  ) throws -> ProgressSubjectDTO? {
    try database.read { db in
      guard let subject = try fetchSubject(in: db, id: subjectId) else {
        return nil
      }
      guard matchesProgressFilters(subject, progressTab: progressTab, search: search) else {
        return nil
      }
      return try makeProgressSubject(in: db, subject, episodeWindowSize: episodeWindowSize)
    }
  }

  public func fetchProgressSubjects(
    progressTab: SubjectType,
    progressSortMode: ProgressSortMode,
    search: String,
    episodeWindowSize: Int,
    limit: Int,
    offset: Int
  ) throws -> PagedDTO<ProgressSubjectDTO> {
    try database.read { db in
      if progressSortMode == .collectedAt {
        let (whereSQL, arguments) = progressSubjectFilter(progressTab: progressTab, search: search)
        let total = try countSubjects(in: db, whereSQL: whereSQL, arguments: arguments)
        let subjects = try fetchSubjects(
          in: db,
          whereSQL: whereSQL,
          arguments: arguments,
          orderSQL: "collected_at DESC",
          limit: limit,
          offset: offset
        )
        let items = try makeProgressSubjects(
          in: db,
          subjects,
          episodeWindowSize: episodeWindowSize
        )
        return PagedDTO(data: items, total: total)
      }

      let subjectIds = try fetchProgressSubjectIds(
        in: db,
        progressTab: progressTab,
        progressSortMode: progressSortMode,
        search: search
      )
      let pageIds = Array(subjectIds.dropFirst(offset).prefix(limit))
      let subjectsById = try fetchSubjectsById(in: db, pageIds)
      let subjects = pageIds.compactMap { subjectsById[$0] }
      let items = try makeProgressSubjects(
        in: db,
        subjects,
        episodeWindowSize: episodeWindowSize
      )
      return PagedDTO(data: items, total: subjectIds.count)
    }
  }

  public func fetchCollectedSubjectSearchable(
    limit: Int = 50,
    offset: Int = 0
  ) throws -> PagedDTO<SearchableItem> {
    try database.read { db in
      let total = try countSubjects(in: db, whereSQL: "ctype != 0", arguments: [])
      let items = try fetchSubjects(
        in: db,
        whereSQL: "ctype != 0",
        arguments: [],
        orderSQL: nil,
        limit: limit,
        offset: offset
      ).map { $0.searchable() }
      return PagedDTO(data: items, total: total)
    }
  }

  public func countSubjects(
    subjectType: SubjectType?,
    collectionType: CollectionType?
  ) throws -> Int {
    try database.read { db in
      let filter = subjectFilter(subjectType: subjectType, collectionType: collectionType)
      return try countSubjects(in: db, whereSQL: filter.sql, arguments: filter.arguments)
    }
  }

  public func fetchProgressCounts() throws -> [SubjectType: Int] {
    try database.read { db in
      var counts: [SubjectType: Int] = [:]
      for type in SubjectType.progressTypes {
        let filter = progressSubjectFilter(progressTab: type, search: "")
        counts[type] = try countSubjects(in: db, whereSQL: filter.sql, arguments: filter.arguments)
      }
      return counts
    }
  }

  public func fetchProgressSubjectIds(
    progressTab: SubjectType,
    progressSortMode: ProgressSortMode,
    search: String
  ) throws -> [Int] {
    try database.read { db in
      try fetchProgressSubjectIds(
        in: db,
        progressTab: progressTab,
        progressSortMode: progressSortMode,
        search: search
      )
    }
  }

  public func exportSubjectsToCSV(
    subjectType: SubjectType?,
    collectionType: CollectionType?,
    fields: Set<ExportableField>,
    coverSize: CoverExportSize = .r400
  ) throws -> URL? {
    try database.read { db in
      let filter = subjectFilter(subjectType: subjectType, collectionType: collectionType)
      let subjects = try fetchSubjects(
        in: db,
        whereSQL: filter.sql,
        arguments: filter.arguments,
        orderSQL: "collected_at DESC"
      )
      return ExportManager.exportSubjects(
        subjects: subjects,
        fields: fields,
        coverSize: coverSize
      )
    }
  }
}

// MARK: - update user collection
extension DatabaseOperator {
  public func updateSubjectProgress(subjectId: Int, eps: Int?, vols: Int?) throws {
    try database.write { db in
      guard let subject = try fetchSubject(in: db, id: subjectId) else {
        return
      }
      if let eps {
        subject.interest?.epStatus = eps
      }
      if let vols {
        subject.interest?.volStatus = vols
      }
      let now = Int(Date().timeIntervalSince1970) - 1
      subject.interest?.updatedAt = now
      subject.collectedAt = now

      switch subject.typeEnum {
      case .anime, .real:
        if let eps {
          let rows = try Row.fetchAll(
            db,
            sql: "SELECT * FROM episodes WHERE subject_id = ? AND type = ? ORDER BY sort ASC",
            arguments: [subjectId, EpisodeType.main.rawValue]
          )
          for (idx, row) in rows.enumerated() {
            let episode = Episode(row: row, subject: subject)
            if idx < eps {
              episode.status = EpisodeCollectionType.collect.rawValue
            } else if episode.status == EpisodeCollectionType.collect.rawValue {
              episode.status = EpisodeCollectionType.none.rawValue
            }
            try upsertEpisode(episode, in: db)
          }
        }
      default:
        break
      }
      try upsertSubject(subject, in: db)
    }
  }

  public func updateSubjectCollection(
    subjectId: Int,
    type: CollectionType?,
    rate: Int?,
    comment: String?,
    priv: Bool?,
    tags: [String]?,
    progress: Bool?
  ) throws {
    try database.write { db in
      guard let subject = try fetchSubject(in: db, id: subjectId) else {
        return
      }
      let now = Int(Date().timeIntervalSince1970) - 1
      subject.collectedAt = now
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
          updatedAt: now
        )
      } else {
        if let type {
          subject.interest?.type = type
          if type == .collect, let progress, progress {
            subject.interest?.epStatus = subject.eps
            subject.interest?.volStatus = subject.volumes
            try db.execute(
              sql: "UPDATE episodes SET status = ? WHERE subject_id = ? AND type = ?",
              arguments: [
                EpisodeCollectionType.collect.rawValue,
                subjectId,
                EpisodeType.main.rawValue,
              ]
            )
          }
        }
        if let rate {
          subject.interest?.rate = rate
        }
        if let comment {
          subject.interest?.comment = comment
        }
        if let priv {
          subject.interest?.private = priv
        }
        if let tags {
          subject.interest?.tags = tags
        }
      }
      subject.interest?.updatedAt = now
      subject.collectedAt = now
      try upsertSubject(subject, in: db)
    }
  }

  @discardableResult
  public func updateEpisodeCollection(
    episodeId: Int,
    type: EpisodeCollectionType,
    batch: Bool = false
  ) throws -> Int? {
    try database.write { db in
      let now = Int(Date().timeIntervalSince1970) - 1
      guard let episode = try fetchEpisode(in: db, id: episodeId, includeSubject: true) else {
        return nil
      }
      let subjectId = episode.subjectId
      guard let subject = try fetchSubject(in: db, id: subjectId) else {
        return nil
      }

      if batch {
        let rows = try Row.fetchAll(
          db,
          sql: "SELECT * FROM episodes WHERE subject_id = ? AND sort <= ? AND type = ?",
          arguments: [subjectId, episode.sort, EpisodeType.main.rawValue]
        )
        for row in rows {
          let item = Episode(row: row, subject: subject)
          item.status = EpisodeCollectionType.collect.rawValue
          item.collectedAt = now
          try upsertEpisode(item, in: db)
        }
        subject.interest?.epStatus = rows.count
      } else {
        let previousType = episode.collectionTypeEnum
        episode.status = type.rawValue
        episode.collectedAt = now
        try upsertEpisode(episode, in: db)
        if episode.typeEnum == .main {
          let epStatus = subject.interest?.epStatus ?? 0
          let delta =
            switch (previousType == .collect, type == .collect) {
            case (false, true):
              1
            case (true, false):
              -1
            default:
              0
            }
          subject.interest?.epStatus = max(0, epStatus + delta)
        }
      }
      subject.interest?.updatedAt = now
      subject.collectedAt = now
      try upsertSubject(subject, in: db)
      return subjectId
    }
  }

  public func updateCharacterCollection(characterId: Int, collectedAt: Int) throws {
    try database.write { db in
      guard let character = try fetchCharacter(in: db, id: characterId) else {
        return
      }
      character.collectedAt = collectedAt
      try upsertCharacter(character, in: db)
    }
  }

  public func updatePersonCollection(personId: Int, collectedAt: Int) throws {
    try database.write { db in
      guard let person = try fetchPerson(in: db, id: personId) else {
        return
      }
      person.collectedAt = collectedAt
      try upsertPerson(person, in: db)
    }
  }
}

// MARK: - save
extension DatabaseOperator {
  @discardableResult
  public func saveUser(_ item: UserDTO) throws -> Bool {
    try database.write { db in
      let user = User(item)
      let created = try fetchUser(in: db, username: item.username) == nil
      try upsertUser(user, in: db)
      return created
    }
  }

  public func saveCalendarItem(weekday: Int, items: [BangumiCalendarItemDTO]) throws {
    try database.write { db in
      try upsertCalendar(BangumiCalendar(weekday: weekday, items: items), in: db)
    }
  }

  public func saveTrendingSubjects(type: Int, items: [TrendingSubjectDTO]) throws {
    try database.write { db in
      try upsertTrendingSubject(TrendingSubject(type: type, items: items), in: db)
    }
  }

  @discardableResult
  public func saveEpisode(_ item: EpisodeDTO) throws -> Bool {
    try database.write { db in
      let created = try fetchEpisode(in: db, id: item.id, includeSubject: false) == nil
      let episode = try makeEpisodeForSaving(item, in: db)
      try upsertEpisode(episode, in: db)
      return created
    }
  }

  public func saveEpisodes(subjectId: Int, items: [EpisodeDTO]) throws {
    guard !items.isEmpty else { return }
    try database.write { db in
      var subjectRef = try fetchSubject(in: db, id: subjectId)
      if subjectRef == nil, let slim = items.first?.subject {
        subjectRef = try ensureSubject(slim, in: db).0
      }
      for item in items {
        let episode = try makeEpisodeForSaving(item, in: db, fallbackSubject: subjectRef)
        try upsertEpisode(episode, in: db)
      }
    }
  }

  public func deleteEpisode(_ episodeId: Int) throws {
    try database.write { db in
      try db.execute(sql: "DELETE FROM episodes WHERE episode_id = ?", arguments: [episodeId])
    }
  }

  public func deleteEpisodesNotIn(subjectId: Int, episodeIds: Set<Int>) throws {
    try database.write { db in
      if episodeIds.isEmpty {
        try db.execute(sql: "DELETE FROM episodes WHERE subject_id = ?", arguments: [subjectId])
        return
      }
      let ids = Array(episodeIds)
      try db.execute(
        sql: """
          DELETE FROM episodes
          WHERE subject_id = ? AND episode_id NOT IN (\(placeholders(ids.count)))
          """,
        arguments: StatementArguments([subjectId] + ids)
      )
    }
  }
}

// MARK: - save subject
extension DatabaseOperator {
  @discardableResult
  public func saveSubject(_ item: SubjectDTO) throws -> Bool {
    try database.write { db in
      let (subject, created) = try ensureSubject(item, in: db)
      try upsertSubject(subject, in: db)
      return created
    }
  }

  @discardableResult
  public func saveSubject(_ item: SlimSubjectDTO) throws -> Bool {
    try database.write { db in
      let (subject, created) = try ensureSubject(item, in: db)
      try upsertSubject(subject, in: db)
      return created
    }
  }

  public func saveSubjectCharacters(subjectId: Int, items: [SubjectCharacterDTO]) throws {
    try saveSubjectDetail(subjectId: subjectId) { $0.characters = items }
  }

  public func saveSubjectOffprints(subjectId: Int, items: [SubjectRelationDTO]) throws {
    try saveSubjectDetail(subjectId: subjectId) { $0.offprints = items }
  }

  public func saveSubjectRelations(subjectId: Int, items: [SubjectRelationDTO]) throws {
    try saveSubjectDetail(subjectId: subjectId) { $0.relations = items }
  }

  public func saveSubjectRecs(subjectId: Int, items: [SubjectRecDTO]) throws {
    try saveSubjectDetail(subjectId: subjectId) { $0.recs = items }
  }

  public func saveSubjectCollects(subjectId: Int, items: [SubjectCollectDTO]) throws {
    try saveSubjectDetail(subjectId: subjectId) { $0.collects = items }
  }

  public func saveSubjectReviews(subjectId: Int, items: [SubjectReviewDTO]) throws {
    try saveSubjectDetail(subjectId: subjectId) { $0.reviews = items }
  }

  public func saveSubjectTopics(subjectId: Int, items: [TopicDTO]) throws {
    try saveSubjectDetail(subjectId: subjectId) { $0.topics = items }
  }

  public func saveSubjectComments(subjectId: Int, items: [SubjectCommentDTO]) throws {
    try saveSubjectDetail(subjectId: subjectId) { $0.comments = items }
  }

  public func saveSubjectIndexes(subjectId: Int, items: [SlimIndexDTO]) throws {
    try saveSubjectDetail(subjectId: subjectId) { $0.indexes = items }
  }

  public func saveSubjectPositions(subjectId: Int, items: [SubjectPositionDTO]) throws {
    try saveSubjectDetail(subjectId: subjectId) { $0.positions = items }
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
    try saveSubjectDetail(subjectId: subjectId) { detail in
      if let characters {
        detail.characters = characters
      }
      if let offprints {
        detail.offprints = offprints
      }
      if let relations {
        detail.relations = relations
      }
      if let recs {
        detail.recs = recs
      }
      if let collects {
        detail.collects = collects
      }
      if let reviews {
        detail.reviews = reviews
      }
      if let topics {
        detail.topics = topics
      }
      if let comments {
        detail.comments = comments
      }
      if let indexes {
        detail.indexes = indexes
      }
    }
  }
}

// MARK: - save character
extension DatabaseOperator {
  @discardableResult
  public func saveCharacter(_ item: CharacterDTO) throws -> Bool {
    try database.write { db in
      let (character, created) = try ensureCharacter(item, in: db)
      try upsertCharacter(character, in: db)
      return created
    }
  }

  @discardableResult
  public func saveCharacter(_ item: SlimCharacterDTO) throws -> Bool {
    try database.write { db in
      let (character, created) = try ensureCharacter(item, in: db)
      try upsertCharacter(character, in: db)
      return created
    }
  }

  public func saveCharacterCasts(characterId: Int, items: [CharacterCastDTO]) throws {
    try database.write { db in
      guard let character = try fetchCharacter(in: db, id: characterId) else { return }
      if character.casts != items {
        character.casts = items
        try upsertCharacter(character, in: db)
      }
    }
  }

  public func saveCharacterRelations(characterId: Int, items: [CharacterRelationDTO]) throws {
    try database.write { db in
      guard let character = try fetchCharacter(in: db, id: characterId) else { return }
      if character.relations != items {
        character.relations = items
        try upsertCharacter(character, in: db)
      }
    }
  }

  public func saveCharacterIndexes(characterId: Int, items: [SlimIndexDTO]) throws {
    try database.write { db in
      guard let character = try fetchCharacter(in: db, id: characterId) else { return }
      if character.indexes != items {
        character.indexes = items
        try upsertCharacter(character, in: db)
      }
    }
  }

  public func saveCharacterDetails(
    characterId: Int,
    casts: [CharacterCastDTO]?,
    relations: [CharacterRelationDTO]?,
    indexes: [SlimIndexDTO]?
  ) throws {
    try database.write { db in
      guard let character = try fetchCharacter(in: db, id: characterId) else { return }
      if let casts, character.casts != casts {
        character.casts = casts
      }
      if let relations, character.relations != relations {
        character.relations = relations
      }
      if let indexes, character.indexes != indexes {
        character.indexes = indexes
      }
      try upsertCharacter(character, in: db)
    }
  }
}

// MARK: - save person
extension DatabaseOperator {
  @discardableResult
  public func savePerson(_ item: PersonDTO) throws -> Bool {
    try database.write { db in
      let (person, created) = try ensurePerson(item, in: db)
      try upsertPerson(person, in: db)
      return created
    }
  }

  @discardableResult
  public func savePerson(_ item: SlimPersonDTO) throws -> Bool {
    try database.write { db in
      let (person, created) = try ensurePerson(item, in: db)
      try upsertPerson(person, in: db)
      return created
    }
  }

  public func savePersonCasts(personId: Int, items: [PersonCastDTO]) throws {
    try database.write { db in
      guard let person = try fetchPerson(in: db, id: personId) else { return }
      if person.casts != items {
        person.casts = items
        try upsertPerson(person, in: db)
      }
    }
  }

  public func savePersonWorks(personId: Int, items: [PersonWorkDTO]) throws {
    try database.write { db in
      guard let person = try fetchPerson(in: db, id: personId) else { return }
      if person.works != items {
        person.works = items
        try upsertPerson(person, in: db)
      }
    }
  }

  public func savePersonRelations(personId: Int, items: [PersonRelationDTO]) throws {
    try database.write { db in
      guard let person = try fetchPerson(in: db, id: personId) else { return }
      if person.relations != items {
        person.relations = items
        try upsertPerson(person, in: db)
      }
    }
  }

  public func savePersonIndexes(personId: Int, items: [SlimIndexDTO]) throws {
    try database.write { db in
      guard let person = try fetchPerson(in: db, id: personId) else { return }
      if person.indexes != items {
        person.indexes = items
        try upsertPerson(person, in: db)
      }
    }
  }

  public func savePersonDetails(
    personId: Int,
    casts: [PersonCastDTO]?,
    works: [PersonWorkDTO]?,
    relations: [PersonRelationDTO]?,
    indexes: [SlimIndexDTO]?
  ) throws {
    try database.write { db in
      guard let person = try fetchPerson(in: db, id: personId) else { return }
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
      try upsertPerson(person, in: db)
    }
  }
}

// MARK: - save group
extension DatabaseOperator {
  @discardableResult
  public func saveGroup(_ item: GroupDTO) throws -> Bool {
    try database.write { db in
      let (group, created) = try ensureGroup(item, in: db)
      try upsertGroup(group, in: db)
      return created
    }
  }

  public func saveGroupRecentMembers(groupName: String, items: [GroupMemberDTO]) throws {
    try database.write { db in
      guard let group = try fetchGroup(in: db, name: groupName) else { return }
      if group.recentMembers != items {
        group.recentMembers = items
        try upsertGroup(group, in: db)
      }
    }
  }

  public func saveGroupModerators(groupName: String, items: [GroupMemberDTO]) throws {
    try database.write { db in
      guard let group = try fetchGroup(in: db, name: groupName) else { return }
      if group.moderators != items {
        group.moderators = items
        try upsertGroup(group, in: db)
      }
    }
  }

  public func saveGroupRecentTopics(groupName: String, items: [TopicDTO]) throws {
    try database.write { db in
      guard let group = try fetchGroup(in: db, name: groupName) else { return }
      if group.recentTopics != items {
        group.recentTopics = items
        try upsertGroup(group, in: db)
      }
    }
  }

  public func saveGroupDetails(
    groupName: String,
    recentMembers: [GroupMemberDTO]?,
    moderators: [GroupMemberDTO]?,
    recentTopics: [TopicDTO]?
  ) throws {
    try database.write { db in
      guard let group = try fetchGroup(in: db, name: groupName) else { return }
      if let recentMembers, group.recentMembers != recentMembers {
        group.recentMembers = recentMembers
      }
      if let moderators, group.moderators != moderators {
        group.moderators = moderators
      }
      if let recentTopics, group.recentTopics != recentTopics {
        group.recentTopics = recentTopics
      }
      try upsertGroup(group, in: db)
    }
  }
}

// MARK: - Draft & Cache
extension DatabaseOperator {
  public func saveDraft(type: String, content: String, id: Int64? = nil) throws -> Int64 {
    try database.write { db in
      let now = Int(Date().timeIntervalSince1970)
      if let id,
        (try Int.fetchOne(
          db,
          sql: "SELECT COUNT(*) FROM drafts WHERE draft_id = ?",
          arguments: [id]
        ) ?? 0) > 0
      {
        try db.execute(
          sql: "UPDATE drafts SET content = ?, updated_at = ? WHERE draft_id = ?",
          arguments: [content, now, id]
        )
        return id
      }

      if let existing = try Int64.fetchOne(
        db,
        sql: "SELECT draft_id FROM drafts WHERE type = ? AND content = ?",
        arguments: [type, content]
      ) {
        return existing
      }

      try db.execute(
        sql: """
          INSERT INTO drafts(type, content, created_at, updated_at)
          VALUES (?, ?, ?, ?)
          """,
        arguments: [type, content, now, now]
      )
      return db.lastInsertedRowID
    }
  }

  public func importDrafts(_ drafts: [DraftDTO]) throws {
    try database.write { db in
      for draft in drafts {
        if let existing = try Row.fetchOne(
          db,
          sql: "SELECT draft_id, created_at, updated_at FROM drafts WHERE type = ? AND content = ?",
          arguments: [draft.type, draft.content]
        ) {
          let existingID: Int64 = existing["draft_id"]
          let existingCreatedAt: Int = existing["created_at"]
          let existingUpdatedAt: Int = existing["updated_at"]
          try db.execute(
            sql: "UPDATE drafts SET created_at = ?, updated_at = ? WHERE draft_id = ?",
            arguments: [
              min(existingCreatedAt, draft.createdAt),
              max(existingUpdatedAt, draft.updatedAt),
              existingID,
            ]
          )
          continue
        }

        try db.execute(
          sql: """
            INSERT INTO drafts(type, content, created_at, updated_at)
            VALUES (?, ?, ?, ?)
            """,
          arguments: [draft.type, draft.content, draft.createdAt, draft.updatedAt]
        )
      }
    }
  }

  public func deleteDraft(id: Int64) {
    do {
      try database.write { db in
        try db.execute(sql: "DELETE FROM drafts WHERE draft_id = ?", arguments: [id])
      }
    } catch {
      Logger.app.error("Failed to delete draft: \(error)")
    }
  }

  public func clearDrafts() throws {
    try database.write { db in
      try db.execute(sql: "DELETE FROM drafts")
    }
  }

  public func saveRakuenSubjectTopicCache(mode: String, items: [SubjectTopicDTO]) throws {
    try database.write { db in
      let cache = RakuenSubjectTopicCache(mode: mode, items: items)
      try upsertRakuenSubjectTopicCache(cache, in: db)
    }
  }

  public func saveRakuenGroupTopicCache(mode: String, items: [GroupTopicDTO]) throws {
    try database.write { db in
      let cache = RakuenGroupTopicCache(mode: mode, items: items)
      try upsertRakuenGroupTopicCache(cache, in: db)
    }
  }

  public func saveRakuenGroupCache(id: String, items: [SlimGroupDTO]) throws {
    try database.write { db in
      let cache = RakuenGroupCache(id: id, items: items)
      try upsertRakuenGroupCache(cache, in: db)
    }
  }

  public func togglePinRakuenGroupCache(group: SlimGroupDTO) throws {
    try database.write { db in
      let cache =
        try Row.fetchOne(
          db,
          sql: "SELECT * FROM rakuen_group_caches WHERE id = ?",
          arguments: ["pin"]
        ).map { RakuenGroupCache(row: $0) }
        ?? RakuenGroupCache(id: "pin", items: [])
      if cache.items.contains(where: { $0.id == group.id }) {
        cache.items.removeAll { $0.id == group.id }
      } else {
        cache.items.insert(group, at: 0)
      }
      cache.updatedAt = Date()
      try upsertRakuenGroupCache(cache, in: db)
    }
  }

  public func updateGroupJoinStatus(name: String, joinedAt: Int) throws {
    try database.write { db in
      guard let group = try fetchGroup(in: db, name: name) else { return }
      group.joinedAt = joinedAt
      try upsertGroup(group, in: db)
    }
  }
}

// MARK: - read helpers
extension DatabaseOperator {
  private func fetchSubject(in db: Database, id: Int) throws -> Subject? {
    try Row.fetchOne(db, sql: "SELECT * FROM subjects WHERE subject_id = ?", arguments: [id])
      .map { Subject(row: $0) }
  }

  private func fetchSubjectsById(in db: Database, _ subjectIds: [Int]) throws -> [Int: Subject] {
    guard !subjectIds.isEmpty else { return [:] }
    let rows = try Row.fetchAll(
      db,
      sql: "SELECT * FROM subjects WHERE subject_id IN (\(placeholders(subjectIds.count)))",
      arguments: StatementArguments(subjectIds)
    )
    return Dictionary(
      uniqueKeysWithValues: rows.map { row in
        let subject = Subject(row: row)
        return (subject.subjectId, subject)
      })
  }

  private func fetchSubjects(
    in db: Database,
    whereSQL: String,
    arguments: StatementArguments,
    orderSQL: String?,
    limit: Int? = nil,
    offset: Int? = nil
  ) throws -> [Subject] {
    var sql = "SELECT * FROM subjects WHERE \(whereSQL)"
    if let orderSQL {
      sql += " ORDER BY \(orderSQL)"
    }
    var sqlArguments = arguments
    if let limit {
      sql += " LIMIT ?"
      sqlArguments += [limit]
    }
    if let offset {
      sql += " OFFSET ?"
      sqlArguments += [offset]
    }
    return try Row.fetchAll(db, sql: sql, arguments: sqlArguments).map { Subject(row: $0) }
  }

  private func fetchEpisode(in db: Database, id: Int, includeSubject: Bool) throws -> Episode? {
    guard
      let row = try Row.fetchOne(
        db,
        sql: "SELECT * FROM episodes WHERE episode_id = ?",
        arguments: [id]
      )
    else {
      return nil
    }
    let subject: Subject?
    if includeSubject {
      let subjectId: Int = row["subject_id"]
      subject = try fetchSubject(in: db, id: subjectId)
    } else {
      subject = nil
    }
    return Episode(row: row, subject: subject)
  }

  private func fetchCharacter(in db: Database, id: Int) throws -> Character? {
    try Row.fetchOne(db, sql: "SELECT * FROM characters WHERE character_id = ?", arguments: [id])
      .map { Character(row: $0) }
  }

  private func fetchPerson(in db: Database, id: Int) throws -> Person? {
    try Row.fetchOne(db, sql: "SELECT * FROM persons WHERE person_id = ?", arguments: [id])
      .map { Person(row: $0) }
  }

  private func fetchGroup(in db: Database, name: String) throws -> ChiiGroup? {
    try Row.fetchOne(db, sql: "SELECT * FROM groups WHERE name = ?", arguments: [name])
      .map { ChiiGroup(row: $0) }
  }

  private func fetchUser(in db: Database, username: String) throws -> User? {
    try Row.fetchOne(db, sql: "SELECT * FROM users WHERE username = ?", arguments: [username])
      .map { User(row: $0) }
  }

  private func fetchSubjectDetail(in db: Database, subjectId: Int) throws -> SubjectDetail? {
    try Row.fetchOne(
      db,
      sql: "SELECT * FROM subject_details WHERE subject_id = ?",
      arguments: [subjectId]
    ).map { SubjectDetail(row: $0) }
  }

  private func collectionTypes(in db: Database, subjectIds: [Int]) throws -> [Int: CollectionType] {
    guard !subjectIds.isEmpty else { return [:] }
    let rows = try Row.fetchAll(
      db,
      sql: """
        SELECT subject_id, ctype FROM subjects
        WHERE subject_id IN (\(placeholders(subjectIds.count)))
        """,
      arguments: StatementArguments(subjectIds)
    )
    return rows.reduce(into: [:]) { result, row in
      let id: Int = row["subject_id"]
      let ctype: Int = row["ctype"]
      result[id] = CollectionType(ctype)
    }
  }

  private func countSubjects(
    in db: Database,
    whereSQL: String,
    arguments: StatementArguments
  ) throws -> Int {
    try Int.fetchOne(
      db,
      sql: "SELECT COUNT(*) FROM subjects WHERE \(whereSQL)",
      arguments: arguments
    ) ?? 0
  }

  private func fetchProgressSubjectIds(
    in db: Database,
    progressTab: SubjectType,
    progressSortMode: ProgressSortMode,
    search: String
  ) throws -> [Int] {
    let filter = progressSubjectFilter(progressTab: progressTab, search: search)
    let subjects = try fetchSubjects(
      in: db,
      whereSQL: filter.sql,
      arguments: filter.arguments,
      orderSQL: "collected_at DESC"
    )

    switch progressSortMode {
    case .airTime:
      let subjectIds = subjects.map(\.subjectId)
      let nextEpisodes = try fetchNextMainEpisodesBySubjectId(in: db, subjectIds: subjectIds)
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

  private func fetchNextMainEpisodesBySubjectId(
    in db: Database,
    subjectIds: [Int]
  ) throws -> [Int: Episode] {
    guard !subjectIds.isEmpty else { return [:] }
    let rows = try Row.fetchAll(
      db,
      sql: """
        SELECT * FROM episodes
        WHERE subject_id IN (\(placeholders(subjectIds.count)))
          AND type = ?
          AND status = 0
        ORDER BY subject_id ASC, sort ASC
        """,
      arguments: StatementArguments(subjectIds + [EpisodeType.main.rawValue])
    )
    var result: [Int: Episode] = [:]
    for row in rows {
      let subjectId: Int = row["subject_id"]
      if result[subjectId] == nil {
        result[subjectId] = Episode(row: row)
      }
    }
    return result
  }

  private func makeProgressSubject(
    in db: Database,
    _ subject: Subject,
    episodeWindowSize: Int
  ) throws -> ProgressSubjectDTO {
    let episodes: [EpisodeDTO]
    switch subject.typeEnum {
    case .anime, .real:
      episodes = try fetchProgressEpisodes(
        in: db, subjectId: subject.subjectId, windowSize: episodeWindowSize)
    default:
      episodes = []
    }
    return ProgressSubjectDTO(subject: SubjectDTO(subject), episodes: episodes)
  }

  private func makeProgressSubjects(
    in db: Database,
    _ subjects: [Subject],
    episodeWindowSize: Int
  ) throws -> [ProgressSubjectDTO] {
    try subjects.map {
      try makeProgressSubject(in: db, $0, episodeWindowSize: episodeWindowSize)
    }
  }

  private func fetchProgressEpisodes(
    in db: Database,
    subjectId: Int,
    windowSize: Int
  ) throws -> [EpisodeDTO] {
    let windowSize = max(1, windowSize)
    let mainType = EpisodeType.main.rawValue
    guard
      let nextRow = try Row.fetchOne(
        db,
        sql: """
          SELECT * FROM episodes
          WHERE subject_id = ? AND type = ? AND status = 0
          ORDER BY sort ASC
          LIMIT 1
          """,
        arguments: [subjectId, mainType]
      )
    else {
      return try Row.fetchAll(
        db,
        sql: """
          SELECT * FROM episodes
          WHERE subject_id = ? AND type = ?
          ORDER BY sort DESC
          LIMIT ?
          """,
        arguments: [subjectId, mainType, windowSize]
      ).reversed().map { EpisodeDTO(Episode(row: $0)) }
    }

    let nextEpisode = Episode(row: nextRow)
    let halfBefore = (windowSize - 1) / 2
    let halfAfter = windowSize - halfBefore - 1

    let before = try Row.fetchAll(
      db,
      sql: """
        SELECT * FROM episodes
        WHERE subject_id = ? AND type = ? AND sort < ?
        ORDER BY sort DESC
        LIMIT ?
        """,
      arguments: [subjectId, mainType, nextEpisode.sort, max(windowSize - 1, 0)]
    ).reversed().map { Episode(row: $0) }

    let after = try Row.fetchAll(
      db,
      sql: """
        SELECT * FROM episodes
        WHERE subject_id = ? AND type = ? AND sort > ?
        ORDER BY sort ASC
        LIMIT ?
        """,
      arguments: [subjectId, mainType, nextEpisode.sort, max(windowSize - 1, 0)]
    ).map { Episode(row: $0) }

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

  private func nextEpisodeDays(subject: Subject, episode: Episode?) -> Int {
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
    let nowDate = calendar.startOfDay(for: Date())
    let airDate = calendar.startOfDay(for: episode.air)
    let components = calendar.dateComponents([.day], from: nowDate, to: airDate)
    return components.day ?? Int.max
  }

  private func matchesProgressFilters(
    _ subject: Subject,
    progressTab: SubjectType,
    search: String
  ) -> Bool {
    let stype = progressTab.rawValue
    let doingType = CollectionType.doing.rawValue
    guard (stype == 0 || subject.type == stype) && subject.ctype == doingType else {
      return false
    }
    return search.isEmpty || subject.name.localizedStandardContains(search)
      || subject.alias.localizedStandardContains(search)
  }
}

// MARK: - write helpers
extension DatabaseOperator {
  @discardableResult
  private func ensureSubject(_ item: SubjectDTO, in db: Database) throws -> (Subject, Bool) {
    if let subject = try fetchSubject(in: db, id: item.id) {
      subject.update(item)
      return (subject, false)
    }
    return (Subject(item), true)
  }

  @discardableResult
  private func ensureSubject(_ item: SlimSubjectDTO, in db: Database) throws -> (Subject, Bool) {
    if let subject = try fetchSubject(in: db, id: item.id) {
      subject.update(item)
      return (subject, false)
    }
    return (Subject(item), true)
  }

  @discardableResult
  private func ensureCharacter(_ item: CharacterDTO, in db: Database) throws -> (Character, Bool) {
    if let character = try fetchCharacter(in: db, id: item.id) {
      character.update(item)
      return (character, false)
    }
    return (Character(item), true)
  }

  @discardableResult
  private func ensureCharacter(_ item: SlimCharacterDTO, in db: Database) throws -> (
    Character, Bool
  ) {
    if let character = try fetchCharacter(in: db, id: item.id) {
      character.update(item)
      return (character, false)
    }
    return (Character(item), true)
  }

  @discardableResult
  private func ensurePerson(_ item: PersonDTO, in db: Database) throws -> (Person, Bool) {
    if let person = try fetchPerson(in: db, id: item.id) {
      person.update(item)
      return (person, false)
    }
    return (Person(item), true)
  }

  @discardableResult
  private func ensurePerson(_ item: SlimPersonDTO, in db: Database) throws -> (Person, Bool) {
    if let person = try fetchPerson(in: db, id: item.id) {
      person.update(item)
      return (person, false)
    }
    return (Person(item), true)
  }

  @discardableResult
  private func ensureGroup(_ item: GroupDTO, in db: Database) throws -> (ChiiGroup, Bool) {
    if let group = try fetchGroup(in: db, name: item.name) {
      group.update(item)
      return (group, false)
    }
    return (ChiiGroup(item), true)
  }

  private func makeEpisodeForSaving(
    _ item: EpisodeDTO,
    in db: Database,
    fallbackSubject: Subject? = nil
  ) throws -> Episode {
    let episode = try fetchEpisode(in: db, id: item.id, includeSubject: false) ?? Episode(item)
    episode.update(item)
    if let slim = item.subject {
      let (subject, _) = try ensureSubject(slim, in: db)
      try upsertSubject(subject, in: db)
      episode.subject = subject
    } else if let fallbackSubject {
      episode.subject = fallbackSubject
    } else {
      episode.subject = try fetchSubject(in: db, id: item.subjectID)
    }
    return episode
  }

  private func saveSubjectDetail(
    subjectId: Int,
    mutate: (SubjectDetail) -> Void
  ) throws {
    try database.write { db in
      guard try fetchSubject(in: db, id: subjectId) != nil else {
        return
      }
      let detail =
        try fetchSubjectDetail(in: db, subjectId: subjectId) ?? SubjectDetail(subjectId: subjectId)
      mutate(detail)
      try upsertSubjectDetail(detail, in: db)
    }
  }

  private func upsertSubject(_ subject: Subject, in db: Database) throws {
    try db.execute(
      sql: """
        INSERT INTO subjects(
          subject_id, airtime_data, collection_data, eps, images_data, infobox_data,
          locked, meta_tags_data, tags_data, name, name_cn, nsfw, platform_data,
          rating_data, series, summary, type, volumes, info, alias, ctype,
          collected_at, interest_data
        )
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        ON CONFLICT(subject_id) DO UPDATE SET
          airtime_data = excluded.airtime_data,
          collection_data = excluded.collection_data,
          eps = excluded.eps,
          images_data = excluded.images_data,
          infobox_data = excluded.infobox_data,
          locked = excluded.locked,
          meta_tags_data = excluded.meta_tags_data,
          tags_data = excluded.tags_data,
          name = excluded.name,
          name_cn = excluded.name_cn,
          nsfw = excluded.nsfw,
          platform_data = excluded.platform_data,
          rating_data = excluded.rating_data,
          series = excluded.series,
          summary = excluded.summary,
          type = excluded.type,
          volumes = excluded.volumes,
          info = excluded.info,
          alias = excluded.alias,
          ctype = excluded.ctype,
          collected_at = excluded.collected_at,
          interest_data = excluded.interest_data
        """,
      arguments: [
        subject.subjectId,
        DatabaseRecordCoding.encode(subject.airtime),
        DatabaseRecordCoding.encode(subject.collection),
        subject.eps,
        DatabaseRecordCoding.encode(subject.images),
        DatabaseRecordCoding.encode(subject.infobox),
        DatabaseRecordCoding.bool(subject.locked),
        DatabaseRecordCoding.encode(subject.metaTags),
        DatabaseRecordCoding.encode(subject.tags),
        subject.name,
        subject.nameCN,
        DatabaseRecordCoding.bool(subject.nsfw),
        DatabaseRecordCoding.encode(subject.platform),
        DatabaseRecordCoding.encode(subject.rating),
        DatabaseRecordCoding.bool(subject.series),
        subject.summary,
        subject.type,
        subject.volumes,
        subject.info,
        subject.alias,
        subject.ctype,
        subject.collectedAt,
        DatabaseRecordCoding.encode(subject.interest),
      ]
    )
    if let detail = subject.detail {
      try upsertSubjectDetail(detail, in: db)
    }
  }

  private func upsertEpisode(_ episode: Episode, in db: Database) throws {
    try db.execute(
      sql: """
        INSERT INTO episodes(
          episode_id, subject_id, type, sort, name, name_cn, duration, airdate,
          comment, desc, disc, status, collected_at
        )
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        ON CONFLICT(episode_id) DO UPDATE SET
          subject_id = excluded.subject_id,
          type = excluded.type,
          sort = excluded.sort,
          name = excluded.name,
          name_cn = excluded.name_cn,
          duration = excluded.duration,
          airdate = excluded.airdate,
          comment = excluded.comment,
          desc = excluded.desc,
          disc = excluded.disc,
          status = excluded.status,
          collected_at = excluded.collected_at
        """,
      arguments: [
        episode.episodeId,
        episode.subjectId,
        episode.type,
        episode.sort,
        episode.name,
        episode.nameCN,
        episode.duration,
        episode.airdate,
        episode.comment,
        episode.desc,
        episode.disc,
        episode.status,
        episode.collectedAt,
      ]
    )
  }

  private func upsertCharacter(_ character: Character, in db: Database) throws {
    try db.execute(
      sql: """
        INSERT INTO characters(
          character_id, collects, comment, images_data, infobox_data, lock,
          name, name_cn, nsfw, role, summary, info, alias, collected_at,
          casts_data, relations_data, indexes_data
        )
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        ON CONFLICT(character_id) DO UPDATE SET
          collects = excluded.collects,
          comment = excluded.comment,
          images_data = excluded.images_data,
          infobox_data = excluded.infobox_data,
          lock = excluded.lock,
          name = excluded.name,
          name_cn = excluded.name_cn,
          nsfw = excluded.nsfw,
          role = excluded.role,
          summary = excluded.summary,
          info = excluded.info,
          alias = excluded.alias,
          collected_at = excluded.collected_at,
          casts_data = excluded.casts_data,
          relations_data = excluded.relations_data,
          indexes_data = excluded.indexes_data
        """,
      arguments: [
        character.characterId,
        character.collects,
        character.comment,
        DatabaseRecordCoding.encode(character.images),
        DatabaseRecordCoding.encode(character.infobox),
        DatabaseRecordCoding.bool(character.lock),
        character.name,
        character.nameCN,
        DatabaseRecordCoding.bool(character.nsfw),
        character.role,
        character.summary,
        character.info,
        character.alias,
        character.collectedAt,
        character.castsData,
        character.relationsData,
        character.indexesData,
      ]
    )
  }

  private func upsertPerson(_ person: Person, in db: Database) throws {
    try db.execute(
      sql: """
        INSERT INTO persons(
          person_id, career_data, collects, comment, images_data, infobox_data,
          lock, name, name_cn, nsfw, summary, type, info, alias, collected_at,
          casts_data, works_data, relations_data, indexes_data
        )
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        ON CONFLICT(person_id) DO UPDATE SET
          career_data = excluded.career_data,
          collects = excluded.collects,
          comment = excluded.comment,
          images_data = excluded.images_data,
          infobox_data = excluded.infobox_data,
          lock = excluded.lock,
          name = excluded.name,
          name_cn = excluded.name_cn,
          nsfw = excluded.nsfw,
          summary = excluded.summary,
          type = excluded.type,
          info = excluded.info,
          alias = excluded.alias,
          collected_at = excluded.collected_at,
          casts_data = excluded.casts_data,
          works_data = excluded.works_data,
          relations_data = excluded.relations_data,
          indexes_data = excluded.indexes_data
        """,
      arguments: [
        person.personId,
        DatabaseRecordCoding.encode(person.career),
        person.collects,
        person.comment,
        DatabaseRecordCoding.encode(person.images),
        DatabaseRecordCoding.encode(person.infobox),
        DatabaseRecordCoding.bool(person.lock),
        person.name,
        person.nameCN,
        DatabaseRecordCoding.bool(person.nsfw),
        person.summary,
        person.type,
        person.info,
        person.alias,
        person.collectedAt,
        person.castsData,
        person.worksData,
        person.relationsData,
        person.indexesData,
      ]
    )
  }

  private func upsertGroup(_ group: ChiiGroup, in db: Database) throws {
    try db.execute(
      sql: """
        INSERT INTO groups(
          group_id, name, nsfw, title, icon_data, creator_data, creator_id,
          desc, cat, accessible, members, posts, topics, created_at, role,
          joined_at, moderators_data, recent_members_data, recent_topics_data
        )
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        ON CONFLICT(group_id) DO UPDATE SET
          name = excluded.name,
          nsfw = excluded.nsfw,
          title = excluded.title,
          icon_data = excluded.icon_data,
          creator_data = excluded.creator_data,
          creator_id = excluded.creator_id,
          desc = excluded.desc,
          cat = excluded.cat,
          accessible = excluded.accessible,
          members = excluded.members,
          posts = excluded.posts,
          topics = excluded.topics,
          created_at = excluded.created_at,
          role = excluded.role,
          joined_at = excluded.joined_at,
          moderators_data = excluded.moderators_data,
          recent_members_data = excluded.recent_members_data,
          recent_topics_data = excluded.recent_topics_data
        """,
      arguments: [
        group.groupId,
        group.name,
        DatabaseRecordCoding.bool(group.nsfw),
        group.title,
        DatabaseRecordCoding.encode(group.icon),
        group.creatorData,
        group.creatorID,
        group.desc,
        group.cat,
        DatabaseRecordCoding.bool(group.accessible),
        group.members,
        group.posts,
        group.topics,
        group.createdAt,
        group.role,
        group.joinedAt,
        group.moderatorsData,
        group.recentMembersData,
        group.recentTopicsData,
      ]
    )
  }

  private func upsertUser(_ user: User, in db: Database) throws {
    try db.execute(
      sql: """
        INSERT INTO users(
          user_id, username, nickname, avatar_data, group_value, joined_at,
          sign, site, location, bio, network_services_data, homepage_data, stats_data
        )
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        ON CONFLICT(user_id) DO UPDATE SET
          username = excluded.username,
          nickname = excluded.nickname,
          avatar_data = excluded.avatar_data,
          group_value = excluded.group_value,
          joined_at = excluded.joined_at,
          sign = excluded.sign,
          site = excluded.site,
          location = excluded.location,
          bio = excluded.bio,
          network_services_data = excluded.network_services_data,
          homepage_data = excluded.homepage_data,
          stats_data = excluded.stats_data
        """,
      arguments: [
        user.userId,
        user.username,
        user.nickname,
        DatabaseRecordCoding.encode(user.avatar),
        user.group,
        user.joinedAt,
        user.sign,
        user.site,
        user.location,
        user.bio,
        user.networkServicesData,
        user.homepageData,
        user.statsData,
      ]
    )
  }

  private func upsertCalendar(_ calendar: BangumiCalendar, in db: Database) throws {
    try db.execute(
      sql: """
        INSERT INTO calendar_entries(weekday, items_data)
        VALUES (?, ?)
        ON CONFLICT(weekday) DO UPDATE SET items_data = excluded.items_data
        """,
      arguments: [calendar.weekday, calendar.itemsData]
    )
  }

  private func upsertTrendingSubject(_ trending: TrendingSubject, in db: Database) throws {
    try db.execute(
      sql: """
        INSERT INTO trending_subjects(type, items_data)
        VALUES (?, ?)
        ON CONFLICT(type) DO UPDATE SET items_data = excluded.items_data
        """,
      arguments: [trending.type, trending.itemsData]
    )
  }

  private func upsertSubjectDetail(_ detail: SubjectDetail, in db: Database) throws {
    try db.execute(
      sql: """
        INSERT INTO subject_details(
          subject_id, positions_data, characters_data, offprints_data, relations_data,
          recs_data, collects_data, reviews_data, topics_data, comments_data, indexes_data
        )
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        ON CONFLICT(subject_id) DO UPDATE SET
          positions_data = excluded.positions_data,
          characters_data = excluded.characters_data,
          offprints_data = excluded.offprints_data,
          relations_data = excluded.relations_data,
          recs_data = excluded.recs_data,
          collects_data = excluded.collects_data,
          reviews_data = excluded.reviews_data,
          topics_data = excluded.topics_data,
          comments_data = excluded.comments_data,
          indexes_data = excluded.indexes_data
        """,
      arguments: [
        detail.subjectId,
        detail.positionsData,
        detail.charactersData,
        detail.offprintsData,
        detail.relationsData,
        detail.recsData,
        detail.collectsData,
        detail.reviewsData,
        detail.topicsData,
        detail.commentsData,
        detail.indexesData,
      ]
    )
  }

  private func upsertRakuenSubjectTopicCache(
    _ cache: RakuenSubjectTopicCache,
    in db: Database
  ) throws {
    try db.execute(
      sql: """
        INSERT INTO rakuen_subject_topic_caches(mode, items_data, updated_at)
        VALUES (?, ?, ?)
        ON CONFLICT(mode) DO UPDATE SET
          items_data = excluded.items_data,
          updated_at = excluded.updated_at
        """,
      arguments: [cache.mode, cache.itemsData, cache.updatedAt.timeIntervalSince1970]
    )
  }

  private func upsertRakuenGroupTopicCache(
    _ cache: RakuenGroupTopicCache,
    in db: Database
  ) throws {
    try db.execute(
      sql: """
        INSERT INTO rakuen_group_topic_caches(mode, items_data, updated_at)
        VALUES (?, ?, ?)
        ON CONFLICT(mode) DO UPDATE SET
          items_data = excluded.items_data,
          updated_at = excluded.updated_at
        """,
      arguments: [cache.mode, cache.itemsData, cache.updatedAt.timeIntervalSince1970]
    )
  }

  private func upsertRakuenGroupCache(_ cache: RakuenGroupCache, in db: Database) throws {
    try db.execute(
      sql: """
        INSERT INTO rakuen_group_caches(id, items_data, updated_at)
        VALUES (?, ?, ?)
        ON CONFLICT(id) DO UPDATE SET
          items_data = excluded.items_data,
          updated_at = excluded.updated_at
        """,
      arguments: [cache.id, cache.itemsData, cache.updatedAt.timeIntervalSince1970]
    )
  }
}

// MARK: - SQL helpers
extension DatabaseOperator {
  private func subjectFilter(
    subjectType: SubjectType?,
    collectionType: CollectionType?
  ) -> (sql: String, arguments: StatementArguments) {
    if let subjectType, let collectionType {
      return ("type = ? AND ctype = ?", [subjectType.rawValue, collectionType.rawValue])
    }
    if let subjectType {
      return ("type = ? AND ctype != 0", [subjectType.rawValue])
    }
    if let collectionType {
      return ("ctype = ?", [collectionType.rawValue])
    }
    return ("ctype != 0", [])
  }

  private func progressSubjectFilter(
    progressTab: SubjectType,
    search: String
  ) -> (sql: String, arguments: StatementArguments) {
    var arguments: StatementArguments = [
      progressTab.rawValue,
      progressTab.rawValue,
      CollectionType.doing.rawValue,
    ]
    var sql = "(? = 0 OR type = ?) AND ctype = ?"
    if !search.isEmpty {
      sql += " AND (name LIKE ? COLLATE NOCASE OR alias LIKE ? COLLATE NOCASE)"
      let pattern = likePattern(search)
      arguments += [pattern, pattern]
    }
    return (sql, arguments)
  }

  private func likePattern(_ value: String) -> String {
    "%\(value.replacingOccurrences(of: "%", with: "\\%").replacingOccurrences(of: "_", with: "\\_"))%"
  }

  private func placeholders(_ count: Int) -> String {
    Array(repeating: "?", count: count).joined(separator: ",")
  }
}
