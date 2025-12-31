import Foundation

enum ExportableField: String, CaseIterable, Identifiable {
  case subjectId
  case name
  case nameCN
  case type
  case eps
  case volumes
  case airDate
  case score
  case rank
  case platform
  case collectionType
  case collectedAt
  case userRate
  case userComment
  case userTags
  case summary
  case info
  case tags
  case wiki
  case cover
  case link

  var id: String { rawValue }

  var label: String {
    switch self {
    case .subjectId: return "条目ID"
    case .name: return "原名"
    case .nameCN: return "中文名"
    case .type: return "类型"
    case .eps: return "话数"
    case .volumes: return "卷数"
    case .airDate: return "放送日期"
    case .score: return "评分"
    case .rank: return "排名"
    case .platform: return "平台"
    case .collectionType: return "收藏状态"
    case .collectedAt: return "收藏日期"
    case .userRate: return "我的评分"
    case .userComment: return "我的评语"
    case .userTags: return "我的标签"
    case .summary: return "简介"
    case .info: return "介绍"
    case .tags: return "标签"
    case .wiki: return "Wiki"
    case .cover: return "封面"
    case .link: return "链接"
    }
  }

  static var defaultFields: Set<ExportableField> {
    [.subjectId, .name, .nameCN, .type, .score, .rank, .collectionType, .collectedAt, .userRate]
  }

  func value(from subject: Subject, coverSize: CoverExportSize = .r400) -> String {
    switch self {
    case .subjectId:
      return String(subject.subjectId)
    case .name:
      return subject.name
    case .nameCN:
      return subject.nameCN
    case .type:
      return subject.typeEnum.description
    case .eps:
      return subject.eps > 0 ? String(subject.eps) : ""
    case .volumes:
      return subject.volumes > 0 ? String(subject.volumes) : ""
    case .airDate:
      return subject.airtime.date
    case .score:
      return subject.rating.score > 0 ? String(format: "%.1f", subject.rating.score) : ""
    case .rank:
      return subject.rating.rank > 0 ? String(subject.rating.rank) : ""
    case .platform:
      return subject.platform.typeCN
    case .collectionType:
      return subject.ctypeEnum.description(subject.typeEnum)
    case .collectedAt:
      if subject.collectedAt > 0 {
        let date = Date(timeIntervalSince1970: TimeInterval(subject.collectedAt))
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
      }
      return ""
    case .userRate:
      if let interest = subject.interest, interest.rate > 0 {
        return String(interest.rate)
      }
      return ""
    case .userComment:
      return subject.interest?.comment ?? ""
    case .userTags:
      return subject.interest?.tags.joined(separator: ", ") ?? ""
    case .summary:
      return subject.summary
    case .info:
      return subject.info
    case .tags:
      return subject.tags.prefix(10).map { $0.name }.joined(separator: ", ")
    case .wiki:
      return subject.infobox.map { item in
        let values = item.values.map { $0.v }.joined(separator: ", ")
        return "\(item.key): \(values)"
      }.joined(separator: "; ")
    case .cover:
      guard let images = subject.images else { return "" }
      switch coverSize {
      case .origin: return images.large
      case .r800: return images.resize(.r800)
      case .r400: return images.resize(.r400)
      case .r200: return images.resize(.r200)
      }
    case .link:
      return subject.link
    }
  }
}

enum CoverExportSize: String, CaseIterable, Identifiable {
  case origin
  case r800
  case r400
  case r200

  var id: String { rawValue }

  var label: String {
    switch self {
    case .origin: return "原图"
    case .r800: return "大图 (800)"
    case .r400: return "中图 (400)"
    case .r200: return "小图 (200)"
    }
  }
}
