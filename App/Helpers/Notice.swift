import Foundation
import SwiftUI

enum NoticeTarget: Hashable {
  case app(NavDestination)
  case external(URL)
}

extension NoticeDTO {
  var message: LocalizedStringResource {
    switch type {
    case 1:
      return "在你的小组话题 \(title) 中发表了新回复"
    case 2:
      return "在小组话题 \(title) 中回复了你"
    case 3:
      return "在你的条目讨论 \(title) 中发表了新回复"
    case 4:
      return "在条目讨论 \(title) 中回复了你"
    case 5:
      return "在角色讨论 \(title) 中发表了新回复"
    case 6:
      return "在角色 \(title) 中回复了你"
    case 7:
      return "在你的日志 \(title) 中发表了新回复"
    case 8:
      return "在日志 \(title) 中回复了你"
    case 9:
      return "在章节讨论 \(title) 中发表了新回复"
    case 10:
      return "在章节讨论 \(title) 中回复了你"
    case 11:
      return "在目录 \(title) 中给你留言了"
    case 12:
      return "在目录 \(title) 中回复了你"
    case 13:
      return "在人物 \(title) 中回复了你"
    case 14:
      return "请求与你成为好友"
    case 15:
      return "通过了你的好友请求"
    case 17:
      return "在你的社团讨论 \(title) 中发表了新回复"
    case 18:
      return "在社团讨论 \(title) 中回复了你"
    case 19:
      return "在同人作品 \(title) 中回复了你"
    case 20:
      return "在你的展会讨论 \(title) 中发表了新回复"
    case 21:
      return "在展会讨论 \(title) 中回复了你"
    case 22:
      return "回复了你的吐槽"
    case 23:
      return "在小组话题 \(title) 中提到了你"
    case 24:
      return "在条目讨论 \(title) 中提到了你"
    case 25:
      return "在角色 \(title) 中提到了你"
    case 26:
      return "在人物讨论 \(title) 中提到了你"
    case 27:
      return "在目录 \(title) 中提到了你"
    case 28:
      return "在 \(title) 中提到了你"
    case 29:
      return "在日志 \(title) 中提到了你"
    case 30:
      return "在章节讨论 \(title) 中提到了你"
    case 31:
      return "在社团 \(title) 的留言板中提到了你"
    case 32:
      return "在社团讨论 \(title) 中提到了你"
    case 33:
      return "在同人作品 \(title) 中提到了你"
    case 34:
      return "在展会讨论 \(title) 中提到了你"
    case 35:
      return "你的条目 patch \(title) 已经被接受"
    case 36:
      return "你的章节 patch \(title) 已经被接受"
    case 37:
      return "你的条目 patch \(title) 已经被拒绝"
    case 38:
      return "你的章节 patch \(title) 已经被拒绝"
    case 39:
      return "你的条目 patch \(title) 已经过期"
    case 40:
      return "你的章节 patch \(title) 已经过期"
    case 41:
      return "你的角色 patch \(title) 已经被接受"
    case 42:
      return "你的人物 patch \(title) 已经被接受"
    case 43:
      return "你的角色 patch \(title) 已经被拒绝"
    case 44:
      return "你的人物 patch \(title) 已经被拒绝"
    case 45:
      return "你的角色 patch \(title) 已经过期"
    case 46:
      return "你的人物 patch \(title) 已经过期"
    case 47:
      return "你参与的条目 patch \(title) 有新回复"
    case 48:
      return "你参与的章节 patch \(title) 有新回复"
    case 49:
      return "你参与的角色 patch \(title) 有新回复"
    case 50:
      return "你参与的人物 patch \(title) 有新回复"
    default:
      return "未知通知类型"
    }
  }

  var target: NoticeTarget? {
    if type == 14 || type == 15 {
      guard !sender.username.isEmpty else {
        return nil
      }
      return .app(.user(sender.username))
    }
    guard mainID > 0 else {
      return nil
    }

    let initialPostID = relatedID > 0 ? relatedID : nil
    switch type {
    case 1, 2, 23:
      return .app(
        .groupTopicDetail(mainID, initialPostID: initialPostID)
      )
    case 3, 4, 24:
      return .app(
        .subjectTopicDetail(mainID, initialPostID: initialPostID)
      )
    case 5, 6, 25:
      return commentTarget(parent: .character(mainID), initialPostID: initialPostID)
    case 7, 8, 29:
      return commentTarget(parent: .blog(mainID), initialPostID: initialPostID)
    case 9, 10, 30:
      return commentTarget(parent: .episode(mainID), initialPostID: initialPostID)
    case 11, 12, 27:
      return commentTarget(parent: .index(mainID), initialPostID: initialPostID)
    case 13, 26:
      return commentTarget(parent: .person(mainID), initialPostID: initialPostID)
    case 22, 28:
      return commentTarget(parent: .timeline(mainID), initialPostID: initialPostID)
    case 35, 37, 39, 47:
      return patchTarget(kind: "s")
    case 36, 38, 40, 48:
      return patchTarget(kind: "e")
    case 41, 43, 45, 49:
      return patchTarget(kind: "c")
    case 42, 44, 46, 50:
      return patchTarget(kind: "p")
    default:
      return nil
    }
  }

  private func commentTarget(
    parent: CommentParentType,
    initialPostID: Int?
  ) -> NoticeTarget {
    .app(
      .commentList(
        CommentListRoute(parent: parent, initialPostID: initialPostID)
      )
    )
  }

  private func patchTarget(kind: String) -> NoticeTarget? {
    var components = URLComponents()
    components.scheme = "https"
    components.host = "patch.bgm38.tv"
    components.path = "/\(kind)/\(mainID)"
    if relatedID > 0 {
      components.fragment = String(relatedID)
    }
    return components.url.map(NoticeTarget.external)
  }
}
