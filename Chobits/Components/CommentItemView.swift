import BBCode
import SwiftUI

enum CommentParentType {
  case blog(Int)
  case character(Int)
  case person(Int)
  case episode(Int)
  case timeline(Int)

  var title: String {
    switch self {
    case .blog:
      return "日志"
    case .character:
      return "角色"
    case .person:
      return "人物"
    case .episode:
      return "章节"
    case .timeline:
      return "时间线"
    }
  }

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

  func reply(commentId: Int?, content: String, token: String) async throws {
    switch self {
    case .blog(let id):
      try await Chii.shared.createBlogComment(
        blogId: id, content: content, replyTo: commentId, token: token)
    case .character(let id):
      try await Chii.shared.createCharacterComment(
        characterId: id, content: content, replyTo: commentId, token: token)
    case .person(let id):
      try await Chii.shared.createPersonComment(
        personId: id, content: content, replyTo: commentId, token: token)
    case .episode(let id):
      try await Chii.shared.createEpisodeComment(
        episodeId: id, content: content, replyTo: commentId, token: token)
    case .timeline(let id):
      try await Chii.shared.createTimelineReply(
        timelineId: id, content: content, replyTo: commentId, token: token)
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
              }
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
              case .normal:
                CommentSubReplyNormalView(
                  type: type, comment: comment,
                  reply: reply, idx: idx, subidx: subidx)
              case .userDelete:
                CommentUserDeleteView(reply.creatorID, reply.user, reply.createdAt)
              default:
                Text(reply.state.description)
              }
            }
          }
        }
      }
    }
    .sheet(isPresented: $showReplyBox) {
      CommentReplyBoxView(type: type, comment: comment)
        .presentationDetents([.large])
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
    case .normal:
      CommentItemNormalView(type: type, comment: comment, idx: idx)
    case .userDelete:
      CommentUserDeleteView(comment.creatorID, comment.user, comment.createdAt)
    default:
      Text(comment.state.description)
    }
  }
}

struct CommentSubReplyNormalView: View {
  let type: CommentParentType
  let comment: CommentDTO
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
            }
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
    .sheet(isPresented: $showReplyBox) {
      CommentReplyBoxView(type: type, comment: comment, reply: reply)
        .presentationDetents([.large])
    }
  }
}

struct CommentReplyBoxView: View {
  let type: CommentParentType
  let comment: CommentDTO?
  let reply: CommentBaseDTO?

  @Environment(\.dismiss) private var dismiss

  @State private var content: String = ""
  @State private var token: String = ""
  @State private var updating: Bool = false

  init(type: CommentParentType, comment: CommentDTO? = nil, reply: CommentBaseDTO? = nil) {
    self.type = type
    self.comment = comment
    self.reply = reply
  }

  func postReply(content: String) async {
    do {
      updating = true
      var content = content
      if let reply = reply {
        let quoteUser = reply.user?.nickname ?? "用户 \(reply.creatorID)"
        let quoteContent = try BBCode().plain(reply.content)
        let quote = "[quote][b]\(quoteUser)[/b]说: \(quoteContent)[/quote]\n"
        content = quote + content
      }
      try await type.reply(commentId: comment?.id, content: content, token: token)
      Notifier.shared.notify(message: "回复成功")
      dismiss()
    } catch {
      Notifier.shared.alert(error: error)
    }
    updating = false
  }

  var title: String {
    if let reply = reply {
      return "回复 \(reply.user?.nickname ?? "用户 \(reply.creatorID)")"
    } else if let comment = comment {
      return "回复 \(comment.user.nickname)"
    } else {
      return "回复 \(type.title)"
    }
  }

  var body: some View {
    ScrollView {
      VStack {
        Text(title)
          .font(.headline)
          .lineLimit(1)
        HStack {
          Button {
            dismiss()
          } label: {
            Label("取消", systemImage: "xmark")
          }
          .disabled(updating)
          .buttonStyle(.bordered)
          Spacer()
          Button {
            Task {
              await postReply(content: content)
            }
          } label: {
            Label("发送", systemImage: "paperplane")
          }
          .disabled(content.isEmpty || token.isEmpty || updating)
          .buttonStyle(.borderedProminent)
        }
        TextInputView(type: "回复", text: $content)
          .textInputStyle(bbcode: true)
        TrunstileView(token: $token).frame(height: 65)
      }.padding()
    }
  }
}
