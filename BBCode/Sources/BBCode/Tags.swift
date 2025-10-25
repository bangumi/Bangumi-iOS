import Foundation
import SwiftUI

typealias HTMLRender = (Node, [String: Any]?) -> String
typealias TextRender = (Node, [String: Any]?) -> TextView
typealias PlainRender = (Node, [String: Any]?) -> String

public enum TextView {
  case view(AnyView)
  case text(Text)
  case string(AttributedString)
}

class TagManager {
  let tags: [TagInfo]

  init(tags: [TagInfo]) {
    var tmptags = tags

    tmptags.sort(by: { a, b in
      if a.label.count > b.label.count {
        return true
      } else {
        return false
      }
    })
    self.tags = tmptags
  }

  func getType(str: String) -> BBType? {
    let str = str.lowercased()
    for tag in tags {
      if tag.label == str {
        return tag.type
      }
    }
    return nil
  }

  func getInfo(str: String) -> TagInfo? {
    let str = str.lowercased()
    for tag in tags {
      if tag.label == str {
        return tag
      }
    }
    return nil
  }

  func getInfo(type: BBType) -> TagInfo? {
    for tag in tags {
      if tag.type == type {
        return tag
      }
    }
    return nil
  }
}

struct TagInfo {
  let label: String
  let type: BBType
  let desc: TagDescription

  init(_ label: String, _ type: BBType, _ desc: TagDescription) {
    self.label = label
    self.type = type
    self.desc = desc
  }
}

struct TagDescription {
  let tagNeeded: Bool
  let isSelfClosing: Bool
  let allowedChildren: [BBType]?
  let allowAttr: Bool
  let isBlock: Bool

  init(
    tagNeeded: Bool, isSelfClosing: Bool, allowedChildren: [BBType]?, allowAttr: Bool, isBlock: Bool
  ) {
    self.tagNeeded = tagNeeded
    self.isSelfClosing = isSelfClosing
    self.allowedChildren = allowedChildren
    self.allowAttr = allowAttr
    self.isBlock = isBlock
  }
}

enum BBType: Int {
  case unknown = 0
  case root
  case plain
  case br
  case paragraphStart, paragraphEnd
  case center, left, right, align
  case quote, code, url, image, photo
  case bold, italic, underline, delete, color, size, mask
  case list, listitem
  case bgm, bmo
  case subject, user
  case background, avatar, float

  static let unsupported: [BBType] = [.background, .avatar, .float]
  static let layout: [BBType] = [.center, .left, .right, .align]
  static let textStyle: [BBType] = [.bold, .italic, .underline, .delete, .color, .size]

  var description: String {
    switch self {
    case .unknown: return "unknown"
    case .root: return "root"
    case .plain: return "plain"
    case .br: return "br"
    case .paragraphStart: return "paragraphStart"
    case .paragraphEnd: return "paragraphEnd"
    case .center: return "center"
    case .left: return "left"
    case .right: return "right"
    case .align: return "align"
    case .quote: return "quote"
    case .code: return "code"
    case .url: return "url"
    case .image: return "image"
    case .photo: return "photo"
    case .bold: return "bold"
    case .italic: return "italic"
    case .underline: return "underline"
    case .delete: return "delete"
    case .color: return "color"
    case .size: return "size"
    case .mask: return "mask"
    case .list: return "list"
    case .listitem: return "listitem"
    case .bgm: return "bgm"
    case .bmo: return "bmo"
    case .subject: return "subject"
    case .user: return "user"
    case .background: return "background"
    case .avatar: return "avatar"
    case .float: return "float"
    }
  }
}

let tags: [TagInfo] = [
  TagInfo(
    "", .root,
    TagDescription(
      tagNeeded: false, isSelfClosing: false,
      allowedChildren: [
        .plain, .br, .paragraphStart, .paragraphEnd,
        .mask, .quote, .code, .url, .image,
        .bgm, .bmo, .photo,
        .list, .subject, .user,
      ] + BBType.unsupported + BBType.layout + BBType.textStyle,
      allowAttr: false,
      isBlock: true
    )
  ),
  TagInfo(
    "", .plain,
    TagDescription(
      tagNeeded: false, isSelfClosing: true,
      allowedChildren: nil,
      allowAttr: false,
      isBlock: false
    )
  ),
  TagInfo(
    "", .br,
    TagDescription(
      tagNeeded: false, isSelfClosing: true,
      allowedChildren: nil,
      allowAttr: false,
      isBlock: false
    )
  ),
  TagInfo(
    "", .paragraphStart,
    TagDescription(
      tagNeeded: false, isSelfClosing: true,
      allowedChildren: nil,
      allowAttr: false,
      isBlock: false
    )
  ),
  TagInfo(
    "", .paragraphEnd,
    TagDescription(
      tagNeeded: false, isSelfClosing: true,
      allowedChildren: nil,
      allowAttr: false,
      isBlock: false
    )
  ),
  TagInfo(
    "bg", .background,
    TagDescription(
      tagNeeded: true, isSelfClosing: false,
      allowedChildren: nil,
      allowAttr: true,
      isBlock: false
    )
  ),
  TagInfo(
    "avatar", .avatar,
    TagDescription(
      tagNeeded: true, isSelfClosing: false,
      allowedChildren: nil,
      allowAttr: true,
      isBlock: false
    )
  ),
  TagInfo(
    "subject", .subject,
    TagDescription(
      tagNeeded: true, isSelfClosing: false,
      allowedChildren: nil,
      allowAttr: true,
      isBlock: false
    )
  ),
  TagInfo(
    "user", .user,
    TagDescription(
      tagNeeded: true, isSelfClosing: false,
      allowedChildren: nil,
      allowAttr: true,
      isBlock: false
    )
  ),
  TagInfo(
    "center", .center,
    TagDescription(
      tagNeeded: true, isSelfClosing: false,
      allowedChildren: [
        .br, .mask, .quote, .code, .url, .image, .subject, .user,
      ] + BBType.unsupported + BBType.layout + BBType.textStyle,
      allowAttr: false,
      isBlock: true
    )
  ),
  TagInfo(
    "left", .left,
    TagDescription(
      tagNeeded: true, isSelfClosing: false,
      allowedChildren: [
        .br, .mask, .quote, .code, .url, .image, .subject, .user,
      ] + BBType.unsupported + BBType.layout + BBType.textStyle,
      allowAttr: false,
      isBlock: true
    )
  ),
  TagInfo(
    "right", .right,
    TagDescription(
      tagNeeded: true, isSelfClosing: false,
      allowedChildren: [
        .br, .mask, .quote, .code, .url, .image, .subject, .user,
      ] + BBType.unsupported + BBType.layout + BBType.textStyle,
      allowAttr: false,
      isBlock: true
    )
  ),
  TagInfo(
    "align", .align,
    TagDescription(
      tagNeeded: true, isSelfClosing: false,
      allowedChildren: [
        .br, .mask, .size, .quote, .code, .url, .image, .subject, .user,
      ] + BBType.unsupported + BBType.layout + BBType.textStyle,
      allowAttr: true,
      isBlock: true
    )
  ),
  TagInfo(
    "float", .float,
    TagDescription(
      tagNeeded: true, isSelfClosing: false,
      allowedChildren: [
        .br, .mask, .quote, .code, .url, .image, .subject, .user,
      ] + BBType.unsupported + BBType.layout + BBType.textStyle,
      allowAttr: true,
      isBlock: true
    )
  ),
  TagInfo(
    "list", .list,
    TagDescription(
      tagNeeded: true, isSelfClosing: false,
      allowedChildren: [
        .list, .listitem, .br, .url, .subject, .user,
      ] + BBType.unsupported + BBType.textStyle,
      allowAttr: false,
      isBlock: true
    )
  ),
  TagInfo(
    "*", .listitem,
    TagDescription(
      tagNeeded: true, isSelfClosing: true,
      allowedChildren: [
        .br, .url, .subject, .user,
      ] + BBType.unsupported + BBType.textStyle,
      allowAttr: false,
      isBlock: true
    )
  ),
  TagInfo(
    "code", .code,
    TagDescription(
      tagNeeded: true, isSelfClosing: false,
      allowedChildren: nil, allowAttr: false,
      isBlock: true
    )
  ),
  TagInfo(
    "quote", .quote,
    TagDescription(
      tagNeeded: true, isSelfClosing: false,
      allowedChildren: [
        .br, .mask, .quote, .code, .url, .image, .subject, .user,
      ] + BBType.unsupported + BBType.layout + BBType.textStyle,
      allowAttr: false,
      isBlock: true
    )
  ),
  TagInfo(
    "url", .url,
    TagDescription(
      tagNeeded: true, isSelfClosing: false,
      allowedChildren: [
        .image, .br,
      ] + BBType.unsupported + BBType.textStyle,
      allowAttr: true, isBlock: false
    )
  ),
  TagInfo(
    "img", .image,
    TagDescription(
      tagNeeded: true, isSelfClosing: false, allowedChildren: nil, allowAttr: true,
      isBlock: true
    )
  ),
  TagInfo(
    "photo", .photo,
    TagDescription(
      tagNeeded: true, isSelfClosing: false, allowedChildren: nil, allowAttr: true,
      isBlock: true
    )
  ),
  TagInfo(
    "b", .bold,
    TagDescription(
      tagNeeded: true, isSelfClosing: false,
      allowedChildren: [
        .br, .url, .subject, .user,
      ] + BBType.unsupported + BBType.layout + BBType.textStyle,
      allowAttr: false,
      isBlock: false
    )
  ),
  TagInfo(
    "i", .italic,
    TagDescription(
      tagNeeded: true, isSelfClosing: false,
      allowedChildren: [
        .br, .url, .subject, .user,
      ] + BBType.unsupported + BBType.textStyle,
      allowAttr: false,
      isBlock: false
    )
  ),
  TagInfo(
    "u", .underline,
    TagDescription(
      tagNeeded: true, isSelfClosing: false,
      allowedChildren: [
        .br, .url, .subject, .user,
      ] + BBType.unsupported + BBType.textStyle,
      allowAttr: false,
      isBlock: false
    )
  ),
  TagInfo(
    "s", .delete,
    TagDescription(
      tagNeeded: true, isSelfClosing: false,
      allowedChildren: [
        .br, .url, .subject, .user,
      ] + BBType.unsupported + BBType.textStyle,
      allowAttr: false,
      isBlock: false
    )
  ),
  TagInfo(
    "color", .color,
    TagDescription(
      tagNeeded: true, isSelfClosing: false,
      allowedChildren: [
        .br, .url, .subject, .user,
      ] + BBType.unsupported + BBType.layout + BBType.textStyle,
      allowAttr: true,
      isBlock: false
    )
  ),
  TagInfo(
    "size", .size,
    TagDescription(
      tagNeeded: true, isSelfClosing: false,
      allowedChildren: [
        .url, .mask, .bgm, .bmo, .br, .subject, .user,
      ] + BBType.unsupported + BBType.layout + BBType.textStyle,
      allowAttr: true,
      isBlock: false
    )
  ),
  TagInfo(
    "mask", .mask,
    TagDescription(
      tagNeeded: true, isSelfClosing: false,
      allowedChildren: [
        .br, .subject, .user,
      ] + BBType.unsupported + BBType.textStyle,
      allowAttr: false,
      isBlock: true
    )
  ),
  TagInfo(
    "bgm", .bgm,
    TagDescription(
      tagNeeded: true, isSelfClosing: true,
      allowedChildren: nil, allowAttr: true,
      isBlock: false
    )
  ),
  TagInfo(
    "bmo", .bmo,
    TagDescription(
      tagNeeded: true, isSelfClosing: true,
      allowedChildren: nil, allowAttr: true,
      isBlock: false
    )
  ),
]
