import Foundation

enum SubjectService {
  static func getSubject(_ subjectId: Int) async throws -> SubjectDTO {
    let url = BangumiAPI.priv.build("p1/subjects/\(subjectId)")
    let data = try await APIClient.shared.request(url: url, method: "GET")
    let subject: SubjectDTO = try await APIClient.shared.decodeResponse(data)
    return subject
  }

  static func getSubjects(
    type: SubjectType,
    sort: SubjectSortMode,
    filter: SubjectsBrowseFilter,
    page: Int = 1
  ) async throws -> PagedDTO<SlimSubjectDTO> {
    let url = BangumiAPI.priv.build("p1/subjects")
    var queryItems: [URLQueryItem] = [
      URLQueryItem(name: "type", value: String(type.rawValue)),
      URLQueryItem(name: "sort", value: sort.rawValue),
      URLQueryItem(name: "page", value: String(page)),
    ]
    if let cat = filter.cat {
      queryItems.append(URLQueryItem(name: "cat", value: String(cat.id)))
    }
    if let series = filter.series {
      queryItems.append(URLQueryItem(name: "series", value: String(series)))
    }
    if let year = filter.year {
      queryItems.append(URLQueryItem(name: "year", value: String(year)))
    }
    if let month = filter.month {
      queryItems.append(URLQueryItem(name: "month", value: String(month)))
    }
    if let tags = filter.tags {
      for tag in tags {
        queryItems.append(URLQueryItem(name: "tags", value: tag))
      }
    }
    if let tagsCat = filter.tagsCat {
      queryItems.append(URLQueryItem(name: "tagsCat", value: tagsCat.rawValue))
    }
    let pageURL = url.appending(queryItems: queryItems)
    let data = try await APIClient.shared.request(url: pageURL, method: "GET")
    let resp: PagedDTO<SlimSubjectDTO> = try await APIClient.shared.decodeResponse(data)
    return resp
  }

  static func getSubjectCharacters(
    _ subjectId: Int, type: CastType = .none,
    limit: Int = 20, offset: Int = 0
  ) async throws -> PagedDTO<SubjectCharacterDTO> {
    let url = BangumiAPI.priv.build("p1/subjects/\(subjectId)/characters")
    var queryItems: [URLQueryItem] = [
      URLQueryItem(name: "limit", value: String(limit)),
      URLQueryItem(name: "offset", value: String(offset)),
    ]
    if type != .none {
      queryItems.append(URLQueryItem(name: "type", value: String(type.rawValue)))
    }
    let pageURL = url.appending(queryItems: queryItems)
    let data = try await APIClient.shared.request(url: pageURL, method: "GET")
    let resp: PagedDTO<SubjectCharacterDTO> = try await APIClient.shared.decodeResponse(data)
    return resp
  }

  static func getSubjectComments(_ subjectId: Int, limit: Int, offset: Int = 0) async throws
    -> PagedDTO<SubjectCommentDTO>
  {
    let url = BangumiAPI.priv.build("p1/subjects/\(subjectId)/comments")
    let queryItems: [URLQueryItem] = [
      URLQueryItem(name: "limit", value: String(limit)),
      URLQueryItem(name: "offset", value: String(offset)),
    ]
    let pageURL = url.appending(queryItems: queryItems)
    let data = try await APIClient.shared.request(url: pageURL, method: "GET")
    let resp: PagedDTO<SubjectCommentDTO> = try await APIClient.shared.decodeResponse(data)
    return resp
  }

  static func getSubjectEpisodes(
    _ subjectId: Int, type: EpisodeType? = nil, limit: Int = 100, offset: Int = 0
  ) async throws -> PagedDTO<EpisodeDTO> {
    let url = BangumiAPI.priv.build("p1/subjects/\(subjectId)/episodes")
    var queryItems: [URLQueryItem] = [
      URLQueryItem(name: "limit", value: String(limit)),
      URLQueryItem(name: "offset", value: String(offset)),
    ]
    if let type = type {
      queryItems.append(URLQueryItem(name: "type", value: String(type.rawValue)))
    }
    let pageURL = url.appending(queryItems: queryItems)
    let data = try await APIClient.shared.request(url: pageURL, method: "GET")
    let resp: PagedDTO<EpisodeDTO> = try await APIClient.shared.decodeResponse(data)
    return resp
  }

  static func getSubjectRecs(_ subjectId: Int, limit: Int = 10, offset: Int = 0) async throws
    -> PagedDTO<SubjectRecDTO>
  {
    let url = BangumiAPI.priv.build("p1/subjects/\(subjectId)/recs")
    let queryItems: [URLQueryItem] = [
      URLQueryItem(name: "limit", value: String(limit)),
      URLQueryItem(name: "offset", value: String(offset)),
    ]
    let pageURL = url.appending(queryItems: queryItems)
    let data = try await APIClient.shared.request(url: pageURL, method: "GET")
    let resp: PagedDTO<SubjectRecDTO> = try await APIClient.shared.decodeResponse(data)
    return resp
  }

  static func getSubjectRelations(
    _ subjectId: Int, type: SubjectType = .none, offprint: Bool? = nil, limit: Int = 20,
    offset: Int = 0
  ) async throws -> PagedDTO<SubjectRelationDTO> {
    let url = BangumiAPI.priv.build("p1/subjects/\(subjectId)/relations")
    var queryItems: [URLQueryItem] = [
      URLQueryItem(name: "limit", value: String(limit)),
      URLQueryItem(name: "offset", value: String(offset)),
    ]
    if let offprint = offprint {
      queryItems.append(URLQueryItem(name: "offprint", value: String(offprint)))
    }
    if type != .none {
      queryItems.append(URLQueryItem(name: "type", value: String(type.rawValue)))
    }
    let pageURL = url.appending(queryItems: queryItems)
    let data = try await APIClient.shared.request(url: pageURL, method: "GET")
    let resp: PagedDTO<SubjectRelationDTO> = try await APIClient.shared.decodeResponse(data)
    return resp
  }

  static func getSubjectReviews(_ subjectId: Int, limit: Int = 5, offset: Int = 0) async throws
    -> PagedDTO<SubjectReviewDTO>
  {
    let url = BangumiAPI.priv.build("p1/subjects/\(subjectId)/reviews")
    let queryItems: [URLQueryItem] = [
      URLQueryItem(name: "limit", value: String(limit)),
      URLQueryItem(name: "offset", value: String(offset)),
    ]
    let pageURL = url.appending(queryItems: queryItems)
    let data = try await APIClient.shared.request(url: pageURL, method: "GET")
    let resp: PagedDTO<SubjectReviewDTO> = try await APIClient.shared.decodeResponse(data)
    return resp
  }

  static func getSubjectCollects(
    _ subjectId: Int,
    type: CollectionType = .none,
    mode: FilterMode = .all,
    limit: Int = 20,
    offset: Int = 0
  ) async throws -> PagedDTO<SubjectCollectDTO> {
    let url = BangumiAPI.priv.build("p1/subjects/\(subjectId)/collects")
    var queryItems: [URLQueryItem] = [
      URLQueryItem(name: "limit", value: String(limit)),
      URLQueryItem(name: "offset", value: String(offset)),
    ]
    if type != .none {
      queryItems.append(URLQueryItem(name: "type", value: String(type.rawValue)))
    }
    if mode != .all {
      queryItems.append(URLQueryItem(name: "mode", value: mode.rawValue))
    }
    let pageURL = url.appending(queryItems: queryItems)
    let data = try await APIClient.shared.request(url: pageURL, method: "GET")
    let resp: PagedDTO<SubjectCollectDTO> = try await APIClient.shared.decodeResponse(data)
    return resp
  }

  static func getSubjectStaffPersons(
    _ subjectId: Int, position: Int? = nil, limit: Int = 20, offset: Int = 0
  ) async throws -> PagedDTO<SubjectStaffDTO> {
    let url = BangumiAPI.priv.build("p1/subjects/\(subjectId)/staffs/persons")
    var queryItems: [URLQueryItem] = [
      URLQueryItem(name: "limit", value: String(limit)),
      URLQueryItem(name: "offset", value: String(offset)),
    ]
    if let position = position {
      queryItems.append(URLQueryItem(name: "position", value: String(position)))
    }
    let pageURL = url.appending(queryItems: queryItems)
    let data = try await APIClient.shared.request(url: pageURL, method: "GET")
    let resp: PagedDTO<SubjectStaffDTO> = try await APIClient.shared.decodeResponse(data)
    return resp
  }

  static func getSubjectStaffPositions(_ subjectId: Int, limit: Int = 100, offset: Int = 0)
    async throws -> PagedDTO<SubjectPositionDTO>
  {
    let url = BangumiAPI.priv.build("p1/subjects/\(subjectId)/staffs/positions")
    let queryItems: [URLQueryItem] = [
      URLQueryItem(name: "limit", value: String(limit)),
      URLQueryItem(name: "offset", value: String(offset)),
    ]
    let pageURL = url.appending(queryItems: queryItems)
    let data = try await APIClient.shared.request(url: pageURL, method: "GET")
    let resp: PagedDTO<SubjectPositionDTO> = try await APIClient.shared.decodeResponse(data)
    return resp
  }

  static func getSubjectIndexes(subjectId: Int, limit: Int = 20, offset: Int = 0) async throws
    -> PagedDTO<SlimIndexDTO>
  {
    let url = BangumiAPI.priv.build("p1/subjects/\(subjectId)/indexes")
    let queryItems: [URLQueryItem] = [
      URLQueryItem(name: "limit", value: String(limit)),
      URLQueryItem(name: "offset", value: String(offset)),
    ]
    let pageURL = url.appending(queryItems: queryItems)
    let data = try await APIClient.shared.request(url: pageURL, method: "GET")
    let resp: PagedDTO<SlimIndexDTO> = try await APIClient.shared.decodeResponse(data)
    return resp
  }

  static func getSubjectTopics(_ subjectId: Int, limit: Int, offset: Int = 0) async throws
    -> PagedDTO<TopicDTO>
  {
    let url = BangumiAPI.priv.build("p1/subjects/\(subjectId)/topics")
    let queryItems: [URLQueryItem] = [
      URLQueryItem(name: "limit", value: String(limit)),
      URLQueryItem(name: "offset", value: String(offset)),
    ]
    let pageURL = url.appending(queryItems: queryItems)
    let data = try await APIClient.shared.request(url: pageURL, method: "GET")
    let resp: PagedDTO<TopicDTO> = try await APIClient.shared.decodeResponse(data)
    return resp
  }

  static func updateSubjectProgress(subjectId: Int, eps: Int?, vols: Int?) async throws {
    let url = BangumiAPI.priv.build("p1/collections/subjects/\(subjectId)")
    var body: [String: Any] = [:]
    if let eps {
      body["epStatus"] = eps
    }
    if let vols {
      body["volStatus"] = vols
    }
    if body.isEmpty {
      return
    }

    _ = try await APIClient.shared.request(url: url, method: "PATCH", body: body, auth: .required)
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
    let url = BangumiAPI.priv.build("p1/collections/subjects/\(subjectId)")
    var body: [String: Any] = [:]
    if let type {
      body["type"] = type.rawValue
    }
    if let rate {
      body["rate"] = rate
    }
    if let comment {
      body["comment"] = comment
    }
    if let priv {
      body["private"] = priv
    }
    if let tags {
      body["tags"] = tags
    }
    if let progress {
      body["progress"] = progress
    }
    if body.isEmpty {
      return
    }

    _ = try await APIClient.shared.request(url: url, method: "PUT", body: body, auth: .required)
  }
}
