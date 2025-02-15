import BBCode
import SwiftUI

struct CommentItemNormalView: View {
  let comment: CommentDTO

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
            Spacer()
            Text(comment.createdAt.datetimeDisplay)
              .lineLimit(1)
              .font(.caption)
              .foregroundStyle(.secondary)
          }
          BBCodeView(comment.content)
            .textSelection(.enabled)
          ForEach(comment.replies) { reply in
            VStack(alignment: .leading) {
              Divider()
              switch reply.state {
              case .userDelete:
                CommentUserDeleteView(reply.creatorID, reply.user, reply.createdAt)
              default:
                CommentSubReplyNormalView(reply: reply)
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
  let comment: CommentDTO

  var body: some View {
    switch comment.state {
    case .userDelete:
      CommentUserDeleteView(comment.creatorID, comment.user, comment.createdAt)
    default:
      CommentItemNormalView(comment: comment)
    }
  }
}

struct CommentSubReplyNormalView: View {
  let reply: CommentBaseDTO

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
          Text(reply.createdAt.datetimeDisplay)
            .lineLimit(1)
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        BBCodeView(reply.content)
          .textSelection(.enabled)
      }
    }
  }
}
