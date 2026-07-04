import Foundation

typealias BBCodeHTMLRender = (BBCodeNode, [String: Any]?) -> String
typealias BBCodePlainRender = (BBCodeNode, [String: Any]?) -> String

class BBCodeTagManager {
  let tags: [BBCodeTagInfo]

  init(tags: [BBCodeTagInfo]) {
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

  func getType(str: String) -> BBCodeTagType? {
    let str = str.lowercased()
    for tag in tags {
      if tag.label == str {
        return tag.type
      }
    }
    return nil
  }

  func getInfo(str: String) -> BBCodeTagInfo? {
    let str = str.lowercased()
    for tag in tags {
      if tag.label == str {
        return tag
      }
    }
    return nil
  }

  func getInfo(type: BBCodeTagType) -> BBCodeTagInfo? {
    for tag in tags {
      if tag.type == type {
        return tag
      }
    }
    return nil
  }
}

struct BBCodeTagInfo {
  let label: String
  let type: BBCodeTagType
  let desc: BBCodeTagDescription

  init(_ label: String, _ type: BBCodeTagType, _ desc: BBCodeTagDescription) {
    self.label = label
    self.type = type
    self.desc = desc
  }
}

struct BBCodeTagDescription {
  let tagNeeded: Bool
  let isSelfClosing: Bool
  let allowedChildren: [BBCodeTagType]?
  let allowAttr: Bool
  let isBlock: Bool

  init(
    tagNeeded: Bool, isSelfClosing: Bool, allowedChildren: [BBCodeTagType]?, allowAttr: Bool, isBlock: Bool
  ) {
    self.tagNeeded = tagNeeded
    self.isSelfClosing = isSelfClosing
    self.allowedChildren = allowedChildren
    self.allowAttr = allowAttr
    self.isBlock = isBlock
  }
}

enum BBCodeTagType: Int {
  case unknown = 0
  case root
  case plain
  case br
  case paragraphStart, paragraphEnd
  case center, left, right, align
  case quote, code, url, image, photo
  case bold, italic, underline, delete, color, size, mask, ruby
  case list, listitem
  case bgm, bmo
  case subject, user
  case background, avatar, float

  static let unsupported: [BBCodeTagType] = [.background, .avatar, .float]
  static let layout: [BBCodeTagType] = [.center, .left, .right, .align]
  static let textStyle: [BBCodeTagType] = [.bold, .italic, .underline, .delete, .color, .size, .ruby]

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
    case .ruby: return "ruby"
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

let bbcodeTagDefinitions: [BBCodeTagInfo] = [
  BBCodeTagInfo(
    "", .root,
    BBCodeTagDescription(
      tagNeeded: false, isSelfClosing: false,
      allowedChildren: [
        .plain, .br, .paragraphStart, .paragraphEnd,
        .mask, .quote, .code, .url, .image,
        .bgm, .bmo, .photo,
        .list, .subject, .user,
      ] + BBCodeTagType.unsupported + BBCodeTagType.layout + BBCodeTagType.textStyle,
      allowAttr: false,
      isBlock: true
    )
  ),
  BBCodeTagInfo(
    "", .plain,
    BBCodeTagDescription(
      tagNeeded: false, isSelfClosing: true,
      allowedChildren: nil,
      allowAttr: false,
      isBlock: false
    )
  ),
  BBCodeTagInfo(
    "", .br,
    BBCodeTagDescription(
      tagNeeded: false, isSelfClosing: true,
      allowedChildren: nil,
      allowAttr: false,
      isBlock: false
    )
  ),
  BBCodeTagInfo(
    "", .paragraphStart,
    BBCodeTagDescription(
      tagNeeded: false, isSelfClosing: true,
      allowedChildren: nil,
      allowAttr: false,
      isBlock: false
    )
  ),
  BBCodeTagInfo(
    "", .paragraphEnd,
    BBCodeTagDescription(
      tagNeeded: false, isSelfClosing: true,
      allowedChildren: nil,
      allowAttr: false,
      isBlock: false
    )
  ),
  BBCodeTagInfo(
    "bg", .background,
    BBCodeTagDescription(
      tagNeeded: true, isSelfClosing: false,
      allowedChildren: nil,
      allowAttr: true,
      isBlock: false
    )
  ),
  BBCodeTagInfo(
    "avatar", .avatar,
    BBCodeTagDescription(
      tagNeeded: true, isSelfClosing: false,
      allowedChildren: nil,
      allowAttr: true,
      isBlock: false
    )
  ),
  BBCodeTagInfo(
    "subject", .subject,
    BBCodeTagDescription(
      tagNeeded: true, isSelfClosing: false,
      allowedChildren: nil,
      allowAttr: true,
      isBlock: false
    )
  ),
  BBCodeTagInfo(
    "user", .user,
    BBCodeTagDescription(
      tagNeeded: true, isSelfClosing: false,
      allowedChildren: nil,
      allowAttr: true,
      isBlock: false
    )
  ),
  BBCodeTagInfo(
    "center", .center,
    BBCodeTagDescription(
      tagNeeded: true, isSelfClosing: false,
      allowedChildren: [
        .br, .mask, .quote, .code, .url, .image, .subject, .user,
      ] + BBCodeTagType.unsupported + BBCodeTagType.layout + BBCodeTagType.textStyle,
      allowAttr: false,
      isBlock: true
    )
  ),
  BBCodeTagInfo(
    "left", .left,
    BBCodeTagDescription(
      tagNeeded: true, isSelfClosing: false,
      allowedChildren: [
        .br, .mask, .quote, .code, .url, .image, .subject, .user,
      ] + BBCodeTagType.unsupported + BBCodeTagType.layout + BBCodeTagType.textStyle,
      allowAttr: false,
      isBlock: true
    )
  ),
  BBCodeTagInfo(
    "right", .right,
    BBCodeTagDescription(
      tagNeeded: true, isSelfClosing: false,
      allowedChildren: [
        .br, .mask, .quote, .code, .url, .image, .subject, .user,
      ] + BBCodeTagType.unsupported + BBCodeTagType.layout + BBCodeTagType.textStyle,
      allowAttr: false,
      isBlock: true
    )
  ),
  BBCodeTagInfo(
    "align", .align,
    BBCodeTagDescription(
      tagNeeded: true, isSelfClosing: false,
      allowedChildren: [
        .br, .mask, .size, .quote, .code, .url, .image, .subject, .user,
      ] + BBCodeTagType.unsupported + BBCodeTagType.layout + BBCodeTagType.textStyle,
      allowAttr: true,
      isBlock: true
    )
  ),
  BBCodeTagInfo(
    "float", .float,
    BBCodeTagDescription(
      tagNeeded: true, isSelfClosing: false,
      allowedChildren: [
        .br, .mask, .quote, .code, .url, .image, .subject, .user,
      ] + BBCodeTagType.unsupported + BBCodeTagType.layout + BBCodeTagType.textStyle,
      allowAttr: true,
      isBlock: true
    )
  ),
  BBCodeTagInfo(
    "list", .list,
    BBCodeTagDescription(
      tagNeeded: true, isSelfClosing: false,
      allowedChildren: [
        .list, .listitem, .br, .url, .subject, .user,
      ] + BBCodeTagType.unsupported + BBCodeTagType.textStyle,
      allowAttr: false,
      isBlock: true
    )
  ),
  BBCodeTagInfo(
    "*", .listitem,
    BBCodeTagDescription(
      tagNeeded: true, isSelfClosing: true,
      allowedChildren: [
        .br, .url, .subject, .user,
      ] + BBCodeTagType.unsupported + BBCodeTagType.textStyle,
      allowAttr: false,
      isBlock: true
    )
  ),
  BBCodeTagInfo(
    "code", .code,
    BBCodeTagDescription(
      tagNeeded: true, isSelfClosing: false,
      allowedChildren: nil, allowAttr: false,
      isBlock: true
    )
  ),
  BBCodeTagInfo(
    "quote", .quote,
    BBCodeTagDescription(
      tagNeeded: true, isSelfClosing: false,
      allowedChildren: [
        .br, .mask, .quote, .code, .url, .image, .subject, .user,
      ] + BBCodeTagType.unsupported + BBCodeTagType.layout + BBCodeTagType.textStyle,
      allowAttr: false,
      isBlock: true
    )
  ),
  BBCodeTagInfo(
    "url", .url,
    BBCodeTagDescription(
      tagNeeded: true, isSelfClosing: false,
      allowedChildren: [
        .image, .br,
      ] + BBCodeTagType.unsupported + BBCodeTagType.textStyle,
      allowAttr: true, isBlock: false
    )
  ),
  BBCodeTagInfo(
    "img", .image,
    BBCodeTagDescription(
      tagNeeded: true, isSelfClosing: false, allowedChildren: nil, allowAttr: true,
      isBlock: true
    )
  ),
  BBCodeTagInfo(
    "photo", .photo,
    BBCodeTagDescription(
      tagNeeded: true, isSelfClosing: false, allowedChildren: nil, allowAttr: true,
      isBlock: true
    )
  ),
  BBCodeTagInfo(
    "b", .bold,
    BBCodeTagDescription(
      tagNeeded: true, isSelfClosing: false,
      allowedChildren: [
        .br, .url, .subject, .user,
      ] + BBCodeTagType.unsupported + BBCodeTagType.layout + BBCodeTagType.textStyle,
      allowAttr: false,
      isBlock: false
    )
  ),
  BBCodeTagInfo(
    "i", .italic,
    BBCodeTagDescription(
      tagNeeded: true, isSelfClosing: false,
      allowedChildren: [
        .br, .url, .subject, .user,
      ] + BBCodeTagType.unsupported + BBCodeTagType.textStyle,
      allowAttr: false,
      isBlock: false
    )
  ),
  BBCodeTagInfo(
    "u", .underline,
    BBCodeTagDescription(
      tagNeeded: true, isSelfClosing: false,
      allowedChildren: [
        .br, .url, .subject, .user,
      ] + BBCodeTagType.unsupported + BBCodeTagType.textStyle,
      allowAttr: false,
      isBlock: false
    )
  ),
  BBCodeTagInfo(
    "s", .delete,
    BBCodeTagDescription(
      tagNeeded: true, isSelfClosing: false,
      allowedChildren: [
        .br, .url, .subject, .user,
      ] + BBCodeTagType.unsupported + BBCodeTagType.textStyle,
      allowAttr: false,
      isBlock: false
    )
  ),
  BBCodeTagInfo(
    "color", .color,
    BBCodeTagDescription(
      tagNeeded: true, isSelfClosing: false,
      allowedChildren: [
        .br, .url, .subject, .user,
      ] + BBCodeTagType.unsupported + BBCodeTagType.layout + BBCodeTagType.textStyle,
      allowAttr: true,
      isBlock: false
    )
  ),
  BBCodeTagInfo(
    "size", .size,
    BBCodeTagDescription(
      tagNeeded: true, isSelfClosing: false,
      allowedChildren: [
        .url, .mask, .bgm, .bmo, .br, .subject, .user,
      ] + BBCodeTagType.unsupported + BBCodeTagType.layout + BBCodeTagType.textStyle,
      allowAttr: true,
      isBlock: false
    )
  ),
  BBCodeTagInfo(
    "mask", .mask,
    BBCodeTagDescription(
      tagNeeded: true, isSelfClosing: false,
      allowedChildren: [
        .br, .subject, .user,
      ] + BBCodeTagType.unsupported + BBCodeTagType.textStyle,
      allowAttr: false,
      isBlock: true
    )
  ),
  BBCodeTagInfo(
    "ruby", .ruby,
    BBCodeTagDescription(
      tagNeeded: true, isSelfClosing: false,
      allowedChildren: [
        .br, .subject, .user,
      ] + BBCodeTagType.unsupported + BBCodeTagType.textStyle,
      allowAttr: true,
      isBlock: false
    )
  ),
  BBCodeTagInfo(
    "bgm", .bgm,
    BBCodeTagDescription(
      tagNeeded: true, isSelfClosing: true,
      allowedChildren: nil, allowAttr: true,
      isBlock: false
    )
  ),
  BBCodeTagInfo(
    "bmo", .bmo,
    BBCodeTagDescription(
      tagNeeded: true, isSelfClosing: true,
      allowedChildren: nil, allowAttr: true,
      isBlock: false
    )
  ),
]
