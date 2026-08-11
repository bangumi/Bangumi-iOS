import Foundation

// MARK: - Reply Sort Order

enum ReplySortOrder: String, Codable, CaseIterable {
  case ascending = "asc"
  case descending = "desc"

  var description: String {
    switch self {
    case .ascending: return "顺序"
    case .descending: return "倒序"
    }
  }

  var icon: String {
    switch self {
    case .ascending: return "arrow.up.to.line"
    case .descending: return "arrow.down.to.line"
    }
  }
}

struct ReplySortSelection {
  private var selectedOrder: ReplySortOrder?

  subscript(fallback fallbackOrder: ReplySortOrder) -> ReplySortOrder {
    get {
      selectedOrder ?? fallbackOrder
    }
    set {
      selectedOrder = newValue
    }
  }
}

// MARK: - Reply Filter Mode

enum ReplyFilterMode: String, Codable, CaseIterable {
  case all = "all"
  case reactions = "reactions"
  case poster = "poster"
  case friends = "friends"
  case myself = "myself"

  var description: String {
    switch self {
    case .all: return "全部"
    case .reactions: return "贴贴"
    case .poster: return "楼主"
    case .friends: return "好友"
    case .myself: return "自己"
    }
  }

  var icon: String {
    switch self {
    case .all: return "bubble.left.and.bubble.right"
    case .reactions: return "heart.fill"
    case .poster: return "person.crop.circle"
    case .friends: return "person.2"
    case .myself: return "person"
    }
  }
}

// MARK: - ReplyDTO Extension

extension Array where Element == ReplyDTO {
  /// Filter replies based on filter mode
  func filtered(
    by mode: ReplyFilterMode,
    posterID: Int?,
    myID: Int
  ) -> [ReplyDTO] {
    switch mode {
    case .all:
      return self
    case .reactions:
      return filter { !($0.reactions ?? []).isEmpty }
    case .poster:
      guard let posterID = posterID else { return self }
      return filter { $0.creatorID == posterID }
    case .friends:
      return filter { $0.creator?.isFriend == true }
    case .myself:
      return filter { $0.creatorID == myID }
    }
  }

  /// Sort replies based on sort order
  func sorted(by order: ReplySortOrder) -> [ReplyDTO] {
    switch order {
    case .ascending:
      return self
    case .descending:
      return reversed()
    }
  }
}

extension Array where Element == CommentDTO {
  func filtered(
    by mode: ReplyFilterMode,
    posterID: Int?,
    myID: Int
  ) -> [CommentDTO] {
    switch mode {
    case .all:
      return self
    case .reactions:
      return filter { !($0.reactions ?? []).isEmpty }
    case .poster:
      guard let posterID else { return self }
      return filter { $0.creatorID == posterID }
    case .friends:
      return filter { $0.user.isFriend == true }
    case .myself:
      return filter { $0.creatorID == myID }
    }
  }

  func sorted(by order: ReplySortOrder) -> [CommentDTO] {
    switch order {
    case .ascending:
      return self
    case .descending:
      return reversed()
    }
  }
}
