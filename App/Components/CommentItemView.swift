import BBCode
import SwiftUI

enum CommentParentType {
  case blog(Int)
  case character(Int)
  case person(Int)
  case episode(Int)
  case timeline(Int)
  case index(Int)

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
    case .index:
      return "目录"
    }
  }

  var parentId: Int {
    switch self {
    case .blog(let id):
      return id
    case .character(let id):
      return id
    case .person(let id):
      return id
    case .episode(let id):
      return id
    case .timeline(let id):
      return id
    case .index(let id):
      return id
    }
  }

  func shareLink(commentId: Int) -> URL {
    @AppStorage("shareDomain") var shareDomain: ShareDomain = .chii
    switch self {
    case .blog(let id):
      return URL(string: "\(shareDomain.url)/blog/\(id)#post_\(commentId)")!
    case .character(let id):
      return URL(string: "\(shareDomain.url)/character/\(id)#post_\(commentId)")!
    case .person(let id):
      return URL(string: "\(shareDomain.url)/person/\(id)#post_\(commentId)")!
    case .episode(let id):
      return URL(string: "\(shareDomain.url)/ep/\(id)#post_\(commentId)")!
    case .timeline(let id):
      return URL(string: "\(shareDomain.url)/timeline/\(id)#post_\(commentId)")!
    case .index(let id):
      return URL(string: "\(shareDomain.url)/index/\(id)/comments#post_\(commentId)")!
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
    case .index(let id):
      try await Chii.shared.createIndexComment(
        indexId: id, content: content, replyTo: commentId, token: token)
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

  var body: some View {
    switch comment.state {
    case .normal:
      CommentItemNormalView(type: type, comment: comment, idx: idx)
        .blocklistFilter(comment.creatorID)
    case .userDelete, .adminOffTopic, .adminCloseTopic, .adminReopen, .adminSilentTopic:
      PostTopicActionStateView(
        type.parentId, comment.state, comment.creatorID, comment.user, comment.createdAt)
    default:
      PostStateView(comment.state)
    }
  }
}

struct CommentItemNormalView: View {
  let type: CommentParentType
  let comment: CommentDTO
  let idx: Int

  @AppStorage("profile") var profile: Profile = Profile()
  @AppStorage("friendlist") var friendlist: [Int] = []
  @AppStorage("isAuthenticated") var isAuthenticated: Bool = false
  @AppStorage("anonymizeTopicUsers") var anonymizeTopicUsers: Bool = false

  @State private var showReplyBox: Bool = false
  @State private var showEditBox: Bool = false
  @State private var updating: Bool = false
  @State private var showDeleteConfirm: Bool = false
  @State private var showReportView: Bool = false

  @State private var reactions: [ReactionDTO]

  init(type: CommentParentType, comment: CommentDTO, idx: Int) {
    self.type = type
    self.comment = comment
    self.idx = idx
    self._reactions = State(initialValue: comment.reactions ?? [])
  }

  var anonymizedHash: String {
    AnonymizationHelper.generateHash(topicId: type.parentId, userId: comment.creatorID)
  }

  var anonymizedColor: Color {
    AnonymizationHelper.generateColor(from: anonymizedHash)
  }

  var body: some View {
    VStack(alignment: .leading) {
      HStack(alignment: .top) {
        if anonymizeTopicUsers {
          Rectangle()
            .fill(anonymizedColor)
            .frame(width: 40, height: 40)
            .clipShape(Circle())
            .imageLink(comment.user.link)
        } else {
          ImageView(img: comment.user.avatar?.large)
            .imageStyle(width: 40, height: 40)
            .imageType(.avatar)
            .imageLink(comment.user.link)
        }
        VStack(alignment: .leading) {
          HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 0) {
              HStack(spacing: 4) {
                FriendLabel(uid: comment.creatorID)
                if anonymizeTopicUsers {
                  Text(anonymizedHash.withLink(comment.user.link)).lineLimit(1)
                } else {
                  Text(comment.user.nickname.withLink(comment.user.link)).lineLimit(1)
                }
              }
              Text("#\(idx+1) - \(comment.createdAt.datetimeDisplay)")
                .lineLimit(1)
                .font(.footnote)
                .foregroundStyle(.secondary)
            }
            Spacer()
            ReplyActionButtons(
              onReply: { showReplyBox = true },
              reactionType: {
                if case .episode(let id) = type {
                  return .episodeReply(id)
                }
                return nil
              }(),
              reactions: $reactions,
              onEdit: { showEditBox = true },
              onDelete: { showDeleteConfirm = true },
              onReport: { showReportView = true },
              shareLink: type.shareLink(commentId: comment.id),
              isAuthenticated: isAuthenticated,
              isOwner: comment.creatorID == profile.id,
              updating: updating
            )
          }
          BBCodeView(comment.content)
            .tint(.linkText)
            .textSelection(.enabled)
            .fixedSize(horizontal: false, vertical: true)
          if !reactions.isEmpty, case .episode(let id) = type {
            ReactionsView(type: .episodeReply(id), reactions: $reactions)
          }
          ForEach(Array(zip(comment.replies.indices, comment.replies)), id: \.1) { subidx, reply in
            VStack(alignment: .leading) {
              Divider()
              switch reply.state {
              case .normal:
                CommentSubReplyNormalView(
                  type: type, comment: comment,
                  reply: reply, idx: idx, subidx: subidx)
              case .userDelete, .adminOffTopic, .adminCloseTopic, .adminReopen, .adminSilentTopic:
                PostTopicActionStateView(
                  type.parentId, reply.state, reply.creatorID, reply.user, reply.createdAt)
              default:
                PostStateView(reply.state)
              }
            }.blocklistFilter(reply.creatorID)
          }
        }
      }
    }
    .sheet(isPresented: $showReplyBox) {
      CreateCommentBoxSheet(type: type, comment: comment)
    }
    .sheet(isPresented: $showEditBox) {
      EditCommentBoxSheet(type: type, comment: comment)
    }
    .sheet(isPresented: $showReportView) {
      switch type {
      case .episode:
        ReportSheet(
          reportType: .episodeReply, itemId: comment.id, itemTitle: "评论 #\(idx+1)",
          user: comment.user
        )
      case .character:
        ReportSheet(
          reportType: .characterReply, itemId: comment.id, itemTitle: "评论 #\(idx+1)",
          user: comment.user
        )
      case .person:
        ReportSheet(
          reportType: .personReply, itemId: comment.id, itemTitle: "评论 #\(idx+1)",
          user: comment.user
        )
      case .blog:
        ReportSheet(
          reportType: .blogReply, itemId: comment.id, itemTitle: "评论 #\(idx+1)", user: comment.user
        )
      case .timeline:
        ReportSheet(
          reportType: .timelineReply, itemId: comment.id, itemTitle: "评论 #\(idx+1)",
          user: comment.user
        )
      case .index:
        ReportSheet(
          reportType: .indexReply, itemId: comment.id, itemTitle: "评论 #\(idx+1)", user: comment.user
        )
      }
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

struct CommentSubReplyNormalView: View {
  let type: CommentParentType
  let comment: CommentDTO
  let reply: CommentBaseDTO
  let idx: Int
  let subidx: Int

  @AppStorage("profile") var profile: Profile = Profile()
  @AppStorage("friendlist") var friendlist: [Int] = []
  @AppStorage("isAuthenticated") var isAuthenticated: Bool = false
  @AppStorage("anonymizeTopicUsers") var anonymizeTopicUsers: Bool = false

  @State private var showReplyBox: Bool = false
  @State private var showEditBox: Bool = false
  @State private var updating: Bool = false
  @State private var showDeleteConfirm: Bool = false
  @State private var showReportView: Bool = false

  @State private var reactions: [ReactionDTO]

  init(type: CommentParentType, comment: CommentDTO, reply: CommentBaseDTO, idx: Int, subidx: Int) {
    self.type = type
    self.comment = comment
    self.reply = reply
    self.idx = idx
    self.subidx = subidx
    self._reactions = State(initialValue: reply.reactions ?? [])
  }

  var anonymizedHash: String {
    AnonymizationHelper.generateHash(topicId: type.parentId, userId: reply.creatorID)
  }

  var anonymizedColor: Color {
    AnonymizationHelper.generateColor(from: anonymizedHash)
  }

  var body: some View {
    HStack(alignment: .top) {
      if anonymizeTopicUsers {
        if let user = reply.user {
          Rectangle()
            .fill(anonymizedColor)
            .frame(width: 40, height: 40)
            .clipShape(Circle())
            .imageLink(user.link)
        } else {
          Rectangle()
            .fill(anonymizedColor)
            .frame(width: 40, height: 40)
            .clipShape(Circle())
        }
      } else if let user = reply.user {
        ImageView(img: user.avatar?.large)
          .imageStyle(width: 40, height: 40)
          .imageType(.avatar)
          .imageLink(user.link)
      } else {
        Rectangle().fill(.clear).frame(width: 40, height: 40)
      }
      VStack(alignment: .leading) {
        HStack(alignment: .center) {
          VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 4) {
              FriendLabel(uid: reply.creatorID)
              if anonymizeTopicUsers {
                if let user = reply.user {
                  Text(anonymizedHash.withLink(user.link)).lineLimit(1)
                } else {
                  Text(anonymizedHash).lineLimit(1)
                }
              } else if let user = reply.user {
                Text(user.nickname.withLink(user.link))
                  .lineLimit(1)
              } else {
                Text("用户 \(reply.creatorID)")
                  .lineLimit(1)
              }
            }
            Text("#\(idx+1)-\(subidx+1) - \(reply.createdAt.datetimeDisplay)")
              .lineLimit(1)
              .font(.footnote)
              .foregroundStyle(.secondary)
          }
          Spacer()
          ReplyActionButtons(
            onReply: { showReplyBox = true },
            reactionType: {
              if case .episode(let id) = type {
                return .episodeReply(id)
              }
              return nil
            }(),
            reactions: $reactions,
            onEdit: { showEditBox = true },
            onDelete: { showDeleteConfirm = true },
            onReport: { showReportView = true },
            shareLink: type.shareLink(commentId: reply.id),
            isAuthenticated: isAuthenticated,
            isOwner: reply.creatorID == profile.id,
            updating: updating
          )
        }
        BBCodeView(reply.content)
          .tint(.linkText)
          .textSelection(.enabled)
          .fixedSize(horizontal: false, vertical: true)
        if !reactions.isEmpty, case .episode(let id) = type {
          ReactionsView(type: .episodeReply(id), reactions: $reactions)
        }
      }
    }
    .sheet(isPresented: $showReplyBox) {
      CreateCommentBoxSheet(type: type, comment: comment, reply: reply)
    }
    .sheet(isPresented: $showEditBox) {
      EditCommentBoxSheet(type: type, comment: comment, reply: reply)
    }
    .sheet(isPresented: $showReportView) {
      switch type {
      case .episode:
        ReportSheet(
          reportType: .episodeReply, itemId: reply.id, itemTitle: "回复 #\(idx+1)-\(subidx+1)",
          user: reply.user
        )
      case .character:
        ReportSheet(
          reportType: .characterReply, itemId: reply.id, itemTitle: "回复 #\(idx+1)-\(subidx+1)",
          user: reply.user
        )
      case .person:
        ReportSheet(
          reportType: .personReply, itemId: reply.id, itemTitle: "回复 #\(idx+1)-\(subidx+1)",
          user: reply.user
        )
      case .blog:
        ReportSheet(
          reportType: .blogReply, itemId: reply.id, itemTitle: "回复 #\(idx+1)-\(subidx+1)",
          user: reply.user
        )
      case .timeline:
        ReportSheet(
          reportType: .timelineReply, itemId: reply.id, itemTitle: "回复 #\(idx+1)-\(subidx+1)",
          user: reply.user
        )
      case .index:
        ReportSheet(
          reportType: .indexReply, itemId: reply.id, itemTitle: "回复 #\(idx+1)-\(subidx+1)",
          user: reply.user
        )
      }
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

struct CreateCommentBoxSheet: View {
  let type: CommentParentType
  let comment: CommentDTO?
  let reply: CommentBaseDTO?
  let onSuccess: (() -> Void)?

  @Environment(\.dismiss) private var dismiss

  @State private var content: String = ""
  @State private var token: String = ""
  @State private var showTurnstile: Bool = false
  @State private var updating: Bool = false

  var title: String {
    if let reply = reply {
      return "回复 \(reply.user?.nickname ?? "用户 \(reply.creatorID)")"
    } else if let comment = comment {
      return "回复 \(comment.user.nickname)"
    } else {
      return "回复 \(type.title)"
    }
  }

  init(
    type: CommentParentType, comment: CommentDTO? = nil, reply: CommentBaseDTO? = nil,
    onSuccess: (() -> Void)? = nil
  ) {
    self.type = type
    self.comment = comment
    self.reply = reply
    self.onSuccess = onSuccess
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
      onSuccess?()
      dismiss()
    } catch {
      Notifier.shared.alert(error: error)
    }
    updating = false
  }

  var body: some View {
    NavigationStack {
      ScrollView {
        VStack {
          TextInputView(type: "回复", text: $content)
            .textInputStyle(bbcode: true)
            .disabled(updating)
            .sheet(isPresented: $showTurnstile) {
              TurnstileSheetView(
                token: $token,
                onSuccess: {
                  Task {
                    await postReply(content: content)
                  }
                })
            }
        }.padding()
      }
      .navigationTitle(title)
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button {
            dismiss()
          } label: {
            Label("取消", systemImage: "xmark")
          }
          .disabled(updating)
        }
        ToolbarItem(placement: .confirmationAction) {
          if updating {
            ProgressView()
          } else {
            Button {
              showTurnstile = true
            } label: {
              Label("发送", systemImage: "paperplane")
            }
            .disabled(content.isEmpty)
          }
        }
      }
    }
  }
}

struct EditCommentBoxSheet: View {
  let type: CommentParentType
  let comment: CommentDTO?
  let reply: CommentBaseDTO?
  let onSuccess: (() -> Void)?

  @Environment(\.dismiss) private var dismiss

  @State private var content: String
  @State private var updating: Bool = false

  var title: String {
    if reply != nil {
      return "编辑回复"
    } else if comment != nil {
      return "编辑评论"
    } else {
      return "编辑"
    }
  }

  init(
    type: CommentParentType, comment: CommentDTO? = nil, reply: CommentBaseDTO? = nil,
    onSuccess: (() -> Void)? = nil
  ) {
    self.type = type
    self.comment = comment
    self.reply = reply
    self.onSuccess = onSuccess
    _content = State(initialValue: reply?.content ?? comment?.content ?? "")
  }

  func editComment(content: String) async {
    do {
      updating = true
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
      Notifier.shared.notify(message: "编辑成功")
      onSuccess?()
      dismiss()
    } catch {
      Notifier.shared.alert(error: error)
    }
    updating = false
  }

  var body: some View {
    NavigationStack {
      ScrollView {
        VStack {
          TextInputView(type: "回复", text: $content)
            .textInputStyle(bbcode: true)
            .disabled(updating)
        }.padding()
      }
      .navigationTitle(title)
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button {
            dismiss()
          } label: {
            Label("取消", systemImage: "xmark")
          }
          .disabled(updating)
        }
        ToolbarItem(placement: .confirmationAction) {
          if updating {
            ProgressView()
          } else {
            Button {
              Task {
                await editComment(content: content)
              }
            } label: {
              Label("保存", systemImage: "checkmark")
            }
            .disabled(content.isEmpty)
          }
        }
      }
    }
  }
}
