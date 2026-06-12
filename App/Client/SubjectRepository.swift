import Foundation
import OSLog

enum SubjectRepository {
  private static func saveAndCommit(db: DatabaseOperator, created: Bool) async throws {
    if created {
      try await db.commitImmediately()
    } else {
      await db.commit()
    }
  }

  private static func loadDetail(
    label: String,
    work: @Sendable @escaping () async throws -> Void
  ) -> Task<Void, Never> {
    Task { @Sendable in
      do {
        try await work()
      } catch {
        Logger.api.error("Failed to load \(label): \(error)")
        await MainActor.run {
          Notifier.shared.notify(message: "加载\(label)失败")
        }
      }
    }
  }

  static func loadSubject(_ subjectId: Int) async throws -> SubjectDTO {
    let db = try await AppContext.shared.getDB()
    let item = try await SubjectService.getSubject(subjectId)

    if subjectId != item.id {
      Logger.api.warning("subject id mismatch: \(subjectId) != \(item.id)")
      throw ChiiError(message: "这是一个被合并的条目")
    }

    let created = try await db.saveSubject(item)
    try await saveAndCommit(db: db, created: created)
    if item.interest != nil {
      await SearchIndexing.index([item.searchable()])
    }
    return item
  }

  static func loadSubjectDetails(_ subjectId: Int, offprints: Bool, social: Bool) async throws {
    let db = try await AppContext.shared.getDB()
    let collectsMode: FilterMode? = {
      guard social else { return nil }
      return AppConfig.subjectCollectsFilterMode
    }()

    var tasks: [Task<Void, Never>] = []

    func addTask<T>(
      label: String,
      work: @Sendable @escaping () async throws -> PagedDTO<T>,
      save: @Sendable @escaping (PagedDTO<T>) async throws -> Void
    ) {
      tasks.append(
        loadDetail(label: label) {
          let value = try await work()
          try await save(value)
          await db.commit()
        })
    }

    addTask(
      label: "条目角色",
      work: { try await SubjectService.getSubjectCharacters(subjectId, limit: 12) },
      save: { value in
        try await db.saveSubjectCharacters(subjectId: subjectId, items: value.data)
      }
    )
    addTask(
      label: "关联条目",
      work: { try await SubjectService.getSubjectRelations(subjectId, limit: 10) },
      save: { value in
        try await db.saveSubjectRelations(subjectId: subjectId, items: value.data)
      }
    )
    addTask(
      label: "推荐条目",
      work: { try await SubjectService.getSubjectRecs(subjectId, limit: 10) },
      save: { value in
        try await db.saveSubjectRecs(subjectId: subjectId, items: value.data)
      }
    )
    addTask(
      label: "条目目录",
      work: { try await SubjectService.getSubjectIndexes(subjectId: subjectId, limit: 5) },
      save: { value in
        try await db.saveSubjectIndexes(subjectId: subjectId, items: value.data)
      }
    )

    if offprints {
      addTask(
        label: "条目衍生",
        work: {
          try await SubjectService.getSubjectRelations(subjectId, offprint: true, limit: 100)
        },
        save: { value in
          try await db.saveSubjectOffprints(subjectId: subjectId, items: value.data)
        }
      )
    }

    if let collectsMode {
      addTask(
        label: "收藏用户",
        work: {
          try await SubjectService.getSubjectCollects(subjectId, mode: collectsMode, limit: 10)
        },
        save: { value in
          try await db.saveSubjectCollects(subjectId: subjectId, items: value.data)
        }
      )
      addTask(
        label: "评论",
        work: { try await SubjectService.getSubjectReviews(subjectId, limit: 5) },
        save: { value in
          try await db.saveSubjectReviews(subjectId: subjectId, items: value.data)
        }
      )
      addTask(
        label: "讨论",
        work: { try await SubjectService.getSubjectTopics(subjectId, limit: 5) },
        save: { value in
          try await db.saveSubjectTopics(subjectId: subjectId, items: value.data)
        }
      )
      addTask(
        label: "吐槽",
        work: { try await SubjectService.getSubjectComments(subjectId, limit: 10) },
        save: { value in
          try await db.saveSubjectComments(subjectId: subjectId, items: value.data)
        }
      )
    }

    for task in tasks {
      await task.value
    }
  }

  static func loadSubjectPositions(_ subjectId: Int) async throws {
    let db = try await AppContext.shared.getDB()
    let limit = 100
    var offset = 0
    var items: [SubjectPositionDTO] = []
    while true {
      let response = try await SubjectService.getSubjectStaffPositions(
        subjectId, limit: limit, offset: offset)
      if response.data.isEmpty {
        break
      }
      items.append(contentsOf: response.data)
      offset += limit
      if offset >= response.total {
        break
      }
    }
    try await db.saveSubjectPositions(subjectId: subjectId, items: items)
    await db.commit()
  }

  static func updateSubjectProgress(subjectId: Int, eps: Int?, vols: Int?) async throws {
    try await SubjectService.updateSubjectProgress(subjectId: subjectId, eps: eps, vols: vols)
    let db = try await AppContext.shared.getDB()
    try await db.updateSubjectProgress(subjectId: subjectId, eps: eps, vols: vols)
  }

  static func updateSubjectCollection(
    subjectId: Int,
    type: CollectionType?,
    rate: Int?,
    comment: String?,
    priv: Bool?,
    tags: [String]?,
    progress: Bool?
  ) async throws {
    try await SubjectService.updateSubjectCollection(
      subjectId: subjectId,
      type: type,
      rate: rate,
      comment: comment,
      priv: priv,
      tags: tags,
      progress: progress
    )
    let db = try await AppContext.shared.getDB()
    try await db.updateSubjectCollection(
      subjectId: subjectId,
      type: type,
      rate: rate,
      comment: comment,
      priv: priv,
      tags: tags,
      progress: progress
    )
  }
}
