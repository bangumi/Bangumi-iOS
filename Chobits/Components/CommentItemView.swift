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

  func edit(commentId: Int, content: String) async throws {
    try await Chii.shared.updateComment(type: self, commentId: commentId, content: content)
  }

  func delete(commentId: Int) async throws {
    try await Chii.shared.deleteComment(type: self, commentId: commentId)
  }
}

struct CommentItemView: View {
  let type: CommentParentType
  let comment: CommentDTO
  let idx: Int

  @AppStorage("hideBlocklist") var hideBlocklist: Bool = false
  @AppStorage("profile") var profile: Profile = Profile()

  var body: some View {
    if !hideBlocklist || !profile.blocklist.contains(comment.creatorID) {
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
}

struct CommentItemNormalView: View {
  let type: CommentParentType
  let comment: CommentDTO
  let idx: Int

  @AppStorage("profile") var profile: Profile = Profile()
  @AppStorage("hideBlocklist") var hideBlocklist: Bool = false

  @State private var showReplyBox: Bool = false
  @State private var showEditBox: Bool = false
  @State private var updating: Bool = false
  @State private var showDeleteConfirm: Bool = false

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
              if comment.creatorID == profile.id {
                Button {
                  showEditBox = true
                } label: {
                  Text("编辑")
                }
                Divider()
                Button(role: .destructive) {
                  showDeleteConfirm = true
                } label: {
                  Text("删除")
                }
                .disabled(updating)
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
            if !hideBlocklist || !profile.blocklist.contains(reply.creatorID) {
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
    }
    .sheet(isPresented: $showReplyBox) {
      CommentReplyBoxView(type: type, comment: comment)
        .presentationDetents([.large])
    }
    .sheet(isPresented: $showEditBox) {
      CommentReplyBoxView(type: type, comment: comment, isEdit: true)
        .presentationDetents([.large])
    }
    .alert("确认删除", isPresented: $showDeleteConfirm) {
      Button("取消", role: .cancel) {}
      Button("删除", role: .destructive) {
        Task {
          updating = true
          do {
            try await type.delete(commentId: comment.id)
            Notifier.shared.notify(message: "删除成功")
          } catch {
            Notifier.shared.alert(error: error)
          }
          updating = false
        }
      }
    } message: {
      Text("确定要删除这条评论吗？")
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

struct CommentSubReplyNormalView: View {
  let type: CommentParentType
  let comment: CommentDTO
  let reply: CommentBaseDTO
  let idx: Int
  let subidx: Int

  @AppStorage("profile") var profile: Profile = Profile()
  @State private var showReplyBox: Bool = false
  @State private var showEditBox: Bool = false
  @State private var updating: Bool = false
  @State private var showDeleteConfirm: Bool = false

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
            if reply.creatorID == profile.id {
              Button {
                showEditBox = true
              } label: {
                Text("编辑")
              }
              Divider()
              Button(role: .destructive) {
                showDeleteConfirm = true
              } label: {
                Text("删除")
              }
              .disabled(updating)
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
    .sheet(isPresented: $showEditBox) {
      CommentReplyBoxView(type: type, comment: comment, reply: reply, isEdit: true)
        .presentationDetents([.large])
    }
    .alert("确认删除", isPresented: $showDeleteConfirm) {
      Button("取消", role: .cancel) {}
      Button("删除", role: .destructive) {
        Task {
          updating = true
          do {
            try await type.delete(commentId: reply.id)
            Notifier.shared.notify(message: "删除成功")
          } catch {
            Notifier.shared.alert(error: error)
          }
          updating = false
        }
      }
    } message: {
      Text("确定要删除这条回复吗？")
    }
  }
}

struct CommentReplyBoxView: View {
  let type: CommentParentType
  let comment: CommentDTO?
  let reply: CommentBaseDTO?
  let isEdit: Bool

  @Environment(\.dismiss) private var dismiss

  @State private var content: String = ""
  @State private var token: String = ""
  @State private var updating: Bool = false

  init(
    type: CommentParentType, comment: CommentDTO? = nil, reply: CommentBaseDTO? = nil,
    isEdit: Bool = false
  ) {
    self.type = type
    self.comment = comment
    self.reply = reply
    self.isEdit = isEdit
    if isEdit {
      _content = State(initialValue: reply?.content ?? comment?.content ?? "")
    }
  }

  func postReply(content: String) async {
    do {
      updating = true
      var content = content
      if !isEdit, let reply = reply {
        let quoteUser = reply.user?.nickname ?? "用户 \(reply.creatorID)"
        let quoteContent = try BBCode().plain(reply.content)
        let quote = "[quote][b]\(quoteUser)[/b]说: \(quoteContent)[/quote]\n"
        content = quote + content
      }
      if isEdit {
        let commentId: Int
        if let reply = reply {
          commentId = reply.id
        } else if let comment = comment {
          commentId = comment.id
        } else {
          Notifier.shared.alert(message: "找不到要编辑的评论")
          return
        }
        try await type.edit(commentId: commentId, content: content)
      } else {
        try await type.reply(commentId: comment?.id, content: content, token: token)
      }
      Notifier.shared.notify(message: isEdit ? "编辑成功" : "回复成功")
      dismiss()
    } catch {
      Notifier.shared.alert(error: error)
    }
    updating = false
  }

  var title: String {
    if isEdit {
      if reply != nil {
        return "编辑回复"
      } else if comment != nil {
        return "编辑评论"
      } else {
        return "编辑"
      }
    } else {
      if let reply = reply {
        return "回复 \(reply.user?.nickname ?? "用户 \(reply.creatorID)")"
      } else if let comment = comment {
        return "回复 \(comment.user.nickname)"
      } else {
        return "回复 \(type.title)"
      }
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
            Label(isEdit ? "保存" : "发送", systemImage: isEdit ? "checkmark" : "paperplane")
          }
          .disabled(content.isEmpty || token.isEmpty || updating)
          .buttonStyle(.borderedProminent)
        }
        TextInputView(type: isEdit ? "内容" : "回复", text: $content)
          .textInputStyle(bbcode: true)
        TrunstileView(token: $token).frame(height: 65)
      }.padding()
    }
  }
}
