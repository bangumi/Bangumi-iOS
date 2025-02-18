import BBCode
import SwiftUI

enum CommentParentType {
  case blog(Int)
  case character(Int)
  case person(Int)
  case episode(Int)
  case timeline(Int)

  func shareLink(commentId: Int) -> URL {
    @AppStorage("shareDomain") var shareDomain: ShareDomain = .chii
    switch self {
    case .blog(let id):
      return URL(string: "https://\(shareDomain.rawValue)/blog/\(id)#post_\(commentId)")!
    case .character(let id):
      return URL(string: "https://\(shareDomain.rawValue)/character/\(id)#post_\(commentId)")!
    case .person(let id):
      return URL(string: "https://\(shareDomain.rawValue)/person/\(id)#post_\(commentId)")!
    case .episode(let id):
      return URL(string: "https://\(shareDomain.rawValue)/ep/\(id)#post_\(commentId)")!
    case .timeline(let id):
      return URL(string: "https://\(shareDomain.rawValue)/timeline/\(id)#post_\(commentId)")!
    }
  }
}

struct CommentItemNormalView: View {
  let type: CommentParentType
  let comment: CommentDTO
  let idx: Int

  @State private var showReplyBox: Bool = false

  var body: some View {
    VStack(alignment: .leading) {
      HStack(alignment: .top) {
        ImageView(img: comment.user.avatar?.large)
          .imageStyle(width: 40, height: 40)
          .imageType(.avatar)
          .imageLink(comment.user.link)
        VStack(alignment: .leading) {
          HStack {
            Text(comment.user.header).lineLimit(1)
            Menu {
              Button {
                showReplyBox = true
              } label: {
                Text("回复")
              }.disabled(true)
              Divider()
              ShareLink(item: type.shareLink(commentId: comment.id)) {
                Label("分享", systemImage: "square.and.arrow.up")
              }
            } label: {
              Spacer()
              Text("#\(idx+1) - \(comment.createdAt.datetimeDisplay)")
                .lineLimit(1)
                .font(.caption)
                .foregroundStyle(.secondary)
              Image(systemName: "ellipsis")
                .foregroundStyle(.secondary)
            }.buttonStyle(.plain)
          }
          BBCodeView(comment.content)
            .tint(.linkText)
            .textSelection(.enabled)
          ForEach(Array(zip(comment.replies.indices, comment.replies)), id: \.1) { subidx, reply in
            VStack(alignment: .leading) {
              Divider()
              switch reply.state {
              case .userDelete:
                CommentUserDeleteView(reply.creatorID, reply.user, reply.createdAt)
              default:
                CommentSubReplyNormalView(
                  type: type, reply: reply, idx: idx, subidx: subidx)
              }
            }
          }
        }
      }
    }
  }
}

struct CommentUserDeleteView: View {
  let creatorID: Int
  let creator: SlimUserDTO?
  let createdAt: Int

  init(_ creatorID: Int, _ creator: SlimUserDTO?, _ createdAt: Int) {
    self.creatorID = creatorID
    self.creator = creator
    self.createdAt = createdAt
  }

  var body: some View {
    HStack {
      if let creator = creator {
        Text(creator.nickname.withLink(creator.link)).lineLimit(1)
      } else {
        Text("用户 \(creatorID)")
          .lineLimit(1)
      }
      Text("删除了评论")
        .font(.footnote)
        .foregroundStyle(.secondary)
      Spacer()
      Text(createdAt.datetimeDisplay)
        .lineLimit(1)
        .font(.caption)
        .foregroundStyle(.secondary)
    }
  }
}

struct CommentItemView: View {
  let type: CommentParentType
  let comment: CommentDTO
  let idx: Int

  var body: some View {
    switch comment.state {
    case .userDelete:
      CommentUserDeleteView(comment.creatorID, comment.user, comment.createdAt)
    default:
      CommentItemNormalView(type: type, comment: comment, idx: idx)
    }
  }
}

struct CommentSubReplyNormalView: View {
  let type: CommentParentType
  let reply: CommentBaseDTO
  let idx: Int
  let subidx: Int

  @State private var showReplyBox: Bool = false

  var body: some View {
    HStack(alignment: .top) {
      if let user = reply.user {
        ImageView(img: user.avatar?.large)
          .imageStyle(width: 40, height: 40)
          .imageType(.avatar)
          .imageLink(user.link)
      } else {
        Rectangle().fill(.clear).frame(width: 40, height: 40)
      }
      VStack(alignment: .leading) {
        HStack {
          if let user = reply.user {
            Text(user.nickname.withLink(user.link))
              .lineLimit(1)
          } else {
            Text("用户 \(reply.creatorID)")
              .lineLimit(1)
          }
          Spacer()
          Menu {
            Button {
              showReplyBox = true
            } label: {
              Text("回复")
            }.disabled(true)
            Divider()
            ShareLink(item: type.shareLink(commentId: reply.id)) {
              Label("分享", systemImage: "square.and.arrow.up")
            }
          } label: {
            Text("#\(idx+1)-\(subidx+1) - \(reply.createdAt.datetimeDisplay)")
              .lineLimit(1)
              .font(.caption)
              .foregroundStyle(.secondary)
            Image(systemName: "ellipsis")
              .foregroundStyle(.secondary)
          }.buttonStyle(.plain)
        }
        BBCodeView(reply.content)
          .tint(.linkText)
          .textSelection(.enabled)
      }
    }
  }
}
