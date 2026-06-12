import Foundation
import OSLog

enum SubjectRepository {
  private static func loadDetailValue<T>(
    label: String,
    work: @Sendable @escaping () async throws -> PagedDTO<T>
  ) -> Task<PagedDTO<T>?, Never> {
    Task { @Sendable in
      do {
        return try await work()
      } catch {
        Logger.api.error("Failed to load \(label): \(error)")
        await MainActor.run {
          Notifier.shared.notify(message: "加载\(label)失败")
        }
        return nil
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

    try await db.saveSubject(item)
    try await db.commit()
    if item.interest != nil {
      await SearchIndexing.index([item.searchable()])
    }
    await ProgressSubjectInvalidation.post(
      subjectId: subjectId,
      mayChangeProgressMembership: true
    )
    return item
  }

  static func loadSubjectDetails(_ subjectId: Int, offprints: Bool, social: Bool) async throws {
    let db = try await AppContext.shared.getDB()
    let collectsMode: FilterMode? = {
      guard social else { return nil }
      return AppConfig.subjectCollectsFilterMode
    }()

    let charactersTask = loadDetailValue(
      label: "条目角色",
      work: { try await SubjectService.getSubjectCharacters(subjectId, limit: 12) }
    )
    let relationsTask = loadDetailValue(
      label: "关联条目",
      work: { try await SubjectService.getSubjectRelations(subjectId, limit: 10) }
    )
    let recsTask = loadDetailValue(
      label: "推荐条目",
      work: { try await SubjectService.getSubjectRecs(subjectId, limit: 10) }
    )
    let indexesTask = loadDetailValue(
      label: "条目目录",
      work: { try await SubjectService.getSubjectIndexes(subjectId: subjectId, limit: 5) }
    )

    let offprintsTask: Task<PagedDTO<SubjectRelationDTO>?, Never>? =
      if offprints {
        loadDetailValue(
          label: "条目衍生",
          work: {
            try await SubjectService.getSubjectRelations(subjectId, offprint: true, limit: 100)
          }
        )
      } else {
        nil
      }

    let collectsTask: Task<PagedDTO<SubjectCollectDTO>?, Never>? =
      if let collectsMode {
        loadDetailValue(
          label: "收藏用户",
          work: {
            try await SubjectService.getSubjectCollects(subjectId, mode: collectsMode, limit: 10)
          }
        )
      } else {
        nil
      }
    let reviewsTask: Task<PagedDTO<SubjectReviewDTO>?, Never>? =
      if collectsMode != nil {
        loadDetailValue(
          label: "评论",
          work: { try await SubjectService.getSubjectReviews(subjectId, limit: 5) }
        )
      } else {
        nil
      }
    let topicsTask: Task<PagedDTO<TopicDTO>?, Never>? =
      if collectsMode != nil {
        loadDetailValue(
          label: "讨论",
          work: { try await SubjectService.getSubjectTopics(subjectId, limit: 5) }
        )
      } else {
        nil
      }
    let commentsTask: Task<PagedDTO<SubjectCommentDTO>?, Never>? =
      if collectsMode != nil {
        loadDetailValue(
          label: "吐槽",
          work: { try await SubjectService.getSubjectComments(subjectId, limit: 10) }
        )
      } else {
        nil
      }

    try await db.saveSubjectDetails(
      subjectId: subjectId,
      characters: await charactersTask.value?.data,
      offprints: await offprintsTask?.value?.data,
      relations: await relationsTask.value?.data,
      recs: await recsTask.value?.data,
      collects: await collectsTask?.value?.data,
      reviews: await reviewsTask?.value?.data,
      topics: await topicsTask?.value?.data,
      comments: await commentsTask?.value?.data,
      indexes: await indexesTask.value?.data
    )
    try await db.commit()
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
    try await db.commit()
  }

  static func updateSubjectProgress(subjectId: Int, eps: Int?, vols: Int?) async throws {
    try await SubjectService.updateSubjectProgress(subjectId: subjectId, eps: eps, vols: vols)
    let db = try await AppContext.shared.getDB()
    try await db.updateSubjectProgress(subjectId: subjectId, eps: eps, vols: vols)
    try await db.commit()
    await ProgressSubjectInvalidation.post(subjectId: subjectId)
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
    try await db.commit()
    await ProgressSubjectInvalidation.post(
      subjectId: subjectId,
      mayChangeProgressMembership: true
    )
  }
}
