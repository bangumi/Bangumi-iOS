import BBCode
import SwiftUI

enum TopicParentType {
  case subject(Int)
  case group(String)

  func shareLink(topicId: Int, postId: Int) -> URL {
    @AppStorage("shareDomain") var shareDomain: ShareDomain = .chii
    switch self {
    case .subject:
      return URL(string: "\(shareDomain.url)/subject/-/topic/\(topicId)#post_\(postId)")!
    case .group:
      return URL(string: "\(shareDomain.url)/group/-/topic/\(topicId)#post_\(postId)")!
    }
  }

  func reply(topicId: Int, content: String, replyTo: Int?, token: String) async throws {
    switch self {
    case .subject:
      try await Chii.shared.createSubjectReply(
        topicId: topicId, content: content, replyTo: replyTo, token: token)
    case .group:
      try await Chii.shared.createGroupReply(
        topicId: topicId, content: content, replyTo: replyTo, token: token)
    }
  }

  func editPost(postId: Int, content: String) async throws {
    switch self {
    case .subject:
      try await Chii.shared.editSubjectPost(postId: postId, content: content)
    case .group:
      try await Chii.shared.editGroupPost(postId: postId, content: content)
    }
  }

  func editTopic(topicId: Int, title: String, content: String) async throws {
    switch self {
    case .subject:
      try await Chii.shared.editSubjectTopic(topicId: topicId, title: title, content: content)
    case .group:
      try await Chii.shared.editGroupTopic(topicId: topicId, title: title, content: content)
    }
  }

  func createTopic(title: String, content: String, token: String) async throws {
    switch self {
    case .subject(let subjectId):
      try await Chii.shared.createSubjectTopic(
        subjectId: subjectId, title: title, content: content, token: token)
    case .group(let groupName):
      try await Chii.shared.createGroupTopic(
        groupName: groupName, title: title, content: content, token: token)
    }
  }
}

struct ReplyItemView: View {
  let type: TopicParentType
  let topicId: Int
  let idx: Int
  let reply: ReplyDTO
  let author: SlimUserDTO?

  var body: some View {
    switch reply.state {
    case .normal:
      ReplyItemNormalView(type: type, topicId: topicId, idx: idx, reply: reply, author: author)
        .blocklistFilter(reply.creatorID)
    case .userDelete, .adminOffTopic, .adminCloseTopic, .adminReopen, .adminSilentTopic:
      PostTopicActionStateView(
        topicId, reply.state, reply.creatorID, reply.creator, reply.createdAt, author)
    default:
      PostStateView(reply.state)
    }
  }
}

struct ReplyItemNormalView: View {
  let type: TopicParentType
  let topicId: Int
  let idx: Int
  let reply: ReplyDTO
  let author: SlimUserDTO?

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

  init(type: TopicParentType, topicId: Int, idx: Int, reply: ReplyDTO, author: SlimUserDTO?) {
    self.type = type
    self.topicId = topicId
    self.idx = idx
    self.reply = reply
    self.author = author
    self._reactions = State(initialValue: reply.reactions ?? [])
  }

  var anonymizedHash: String {
    AnonymizationHelper.generateHash(topicId: topicId, userId: reply.creatorID)
  }

  var anonymizedColor: Color {
    AnonymizationHelper.generateColor(from: anonymizedHash)
  }

  var body: some View {
    VStack(alignment: .leading) {
      HStack(alignment: .top) {
        if anonymizeTopicUsers {
          if let creator = reply.creator {
            Rectangle()
              .fill(anonymizedColor)
              .frame(width: 40, height: 40)
              .clipShape(Circle())
              .imageLink(creator.link)
          } else {
            Rectangle()
              .fill(anonymizedColor)
              .frame(width: 40, height: 40)
              .clipShape(Circle())
          }
        } else if let creator = reply.creator {
          ImageView(img: creator.avatar?.large)
            .imageStyle(width: 40, height: 40)
            .imageType(.avatar)
            .imageLink(creator.link)
        } else {
          Rectangle().fill(.clear).frame(width: 40, height: 40)
        }
        VStack(alignment: .leading) {
          HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 0) {
              HStack(spacing: 4) {
                PosterLabel(uid: reply.creatorID, poster: author?.id)
                FriendLabel(uid: reply.creatorID)
                if anonymizeTopicUsers {
                  if let creator = reply.creator {
                    Text(anonymizedHash.withLink(creator.link)).lineLimit(1)
                  } else {
                    Text(anonymizedHash).lineLimit(1)
                  }
                } else if let creator = reply.creator {
                  Text(creator.nickname.withLink(creator.link)).lineLimit(1)
                } else {
                  Text("用户 \(reply.creatorID)")
                    .lineLimit(1)
                }
              }
              Text("#\(idx+1) - \(reply.createdAt.datetimeDisplay)")
                .lineLimit(1)
                .font(.footnote)
                .foregroundStyle(.secondary)
            }
            Spacer()
            ReplyActionButtons(
              onReply: { showReplyBox = true },
              reactionType: {
                switch type {
                case .subject:
                  return .subjectReply(reply.id)
                case .group:
                  return .groupReply(reply.id)
                }
              }(),
              reactions: $reactions,
              onEdit: { showEditBox = true },
              onDelete: { showDeleteConfirm = true },
              onReport: { showReportView = true },
              shareLink: type.shareLink(topicId: topicId, postId: reply.id),
              isAuthenticated: isAuthenticated,
              isOwner: reply.creatorID == profile.id,
              updating: updating
            )
          }
          BBCodeView(reply.content)
            .tint(.linkText)
            .textSelection(.enabled)
            .fixedSize(horizontal: false, vertical: true)
          if !reactions.isEmpty {
            switch type {
            case .subject:
              ReactionsView(type: .subjectReply(reply.id), reactions: $reactions)
            case .group:
              ReactionsView(type: .groupReply(reply.id), reactions: $reactions)
            }
          }
          ForEach(Array(zip(reply.replies.indices, reply.replies)), id: \.1) { subidx, subreply in
            VStack(alignment: .leading) {
              Divider()
              switch subreply.state {
              case .normal:
                SubReplyNormalView(
                  type: type, idx: idx, reply: reply, subidx: subidx, subreply: subreply,
                  author: author, topicId: topicId)
              case .userDelete, .adminOffTopic, .adminCloseTopic, .adminReopen, .adminSilentTopic:
                PostTopicActionStateView(
                  topicId, subreply.state, subreply.creatorID, subreply.creator, subreply.createdAt, author)
              default:
                PostStateView(subreply.state)
              }
            }.blocklistFilter(subreply.creatorID)
          }
        }
      }
      .sheet(isPresented: $showReplyBox) {
        CreateReplyBoxSheet(type: type, topicId: topicId, reply: idx == 0 ? nil : reply)
      }
      .sheet(isPresented: $showEditBox) {
        EditReplyBoxSheet(type: type, topicId: topicId, reply: reply)
      }
      .sheet(isPresented: $showReportView) {
        switch type {
        case .group:
          ReportSheet(
            reportType: .groupReply, itemId: reply.id, itemTitle: "回复 #\(idx+1)",
            user: reply.creator
          )
        case .subject:
          ReportSheet(
            reportType: .subjectReply, itemId: reply.id, itemTitle: "回复 #\(idx+1)",
            user: reply.creator
          )
        }
      }
      .alert("确认删除", isPresented: $showDeleteConfirm) {
        Button("取消", role: .cancel) {}
        Button("删除", role: .destructive) {
          Task {
            updating = true
            do {
              try await Chii.shared.deleteSubjectPost(postId: reply.id)
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
}

struct SubReplyNormalView: View {
  let type: TopicParentType
  let idx: Int
  let reply: ReplyDTO
  let subidx: Int
  let subreply: ReplyBaseDTO
  let author: SlimUserDTO?
  let topicId: Int

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

  init(
    type: TopicParentType,
    idx: Int, reply: ReplyDTO, subidx: Int,
    subreply: ReplyBaseDTO,
    author: SlimUserDTO?, topicId: Int
  ) {
    self.type = type
    self.idx = idx
    self.reply = reply
    self.subidx = subidx
    self.subreply = subreply
    self.author = author
    self.topicId = topicId
    self._reactions = State(initialValue: subreply.reactions ?? [])
  }

  var anonymizedHash: String {
    AnonymizationHelper.generateHash(topicId: topicId, userId: subreply.creatorID)
  }

  var anonymizedColor: Color {
    AnonymizationHelper.generateColor(from: anonymizedHash)
  }

  var body: some View {
    HStack(alignment: .top) {
      if anonymizeTopicUsers {
        if let creator = subreply.creator {
          Rectangle()
            .fill(anonymizedColor)
            .frame(width: 40, height: 40)
            .clipShape(Circle())
            .imageLink(creator.link)
        } else {
          Rectangle()
            .fill(anonymizedColor)
            .frame(width: 40, height: 40)
            .clipShape(Circle())
        }
      } else if let creator = subreply.creator {
        ImageView(img: creator.avatar?.large)
          .imageStyle(width: 40, height: 40)
          .imageType(.avatar)
          .imageLink(creator.link)
      } else {
        Rectangle().fill(.clear).frame(width: 40, height: 40)
      }
      VStack(alignment: .leading) {
        HStack(alignment: .center) {
          VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 4) {
              PosterLabel(uid: subreply.creatorID, poster: author?.id)
              FriendLabel(uid: subreply.creatorID)
              if anonymizeTopicUsers {
                if let creator = subreply.creator {
                  Text(anonymizedHash.withLink(creator.link)).lineLimit(1)
                } else {
                  Text(anonymizedHash).lineLimit(1)
                }
              } else if let creator = subreply.creator {
                Text(creator.nickname.withLink(creator.link))
                  .lineLimit(1)
              } else {
                Text("用户 \(subreply.creatorID)")
                  .lineLimit(1)
              }
            }
            Text("#\(idx+1)-\(subidx+1) - \(subreply.createdAt.datetimeDisplay)")
              .lineLimit(1)
              .font(.footnote)
              .foregroundStyle(.secondary)
          }
          Spacer()
          ReplyActionButtons(
            onReply: { showReplyBox = true },
            reactionType: {
              switch type {
              case .subject:
                return .subjectReply(subreply.id)
              case .group:
                return .groupReply(subreply.id)
              }
            }(),
            reactions: $reactions,
            onEdit: { showEditBox = true },
            onDelete: { showDeleteConfirm = true },
            onReport: { showReportView = true },
            shareLink: type.shareLink(topicId: topicId, postId: subreply.id),
            isAuthenticated: isAuthenticated,
            isOwner: subreply.creatorID == profile.id,
            updating: updating
          )
        }
        BBCodeView(subreply.content)
          .tint(.linkText)
          .textSelection(.enabled)
          .fixedSize(horizontal: false, vertical: true)
        if !reactions.isEmpty {
          switch type {
          case .subject:
            ReactionsView(type: .subjectReply(subreply.id), reactions: $reactions)
          case .group:
            ReactionsView(type: .groupReply(subreply.id), reactions: $reactions)
          }
        }
      }
    }
    .sheet(isPresented: $showReplyBox) {
      CreateReplyBoxSheet(type: type, topicId: topicId, reply: reply, subreply: subreply)
    }
    .sheet(isPresented: $showEditBox) {
      EditReplyBoxSheet(type: type, topicId: topicId, reply: reply, subreply: subreply)
    }
    .sheet(isPresented: $showReportView) {
      switch type {
      case .group:
        ReportSheet(
          reportType: .groupReply, itemId: subreply.id, itemTitle: "回复 #\(idx+1)-\(subidx+1)",
          user: subreply.creator
        )
      case .subject:
        ReportSheet(
          reportType: .subjectReply, itemId: subreply.id, itemTitle: "回复 #\(idx+1)-\(subidx+1)",
          user: subreply.creator
        )
      }
    }
    .alert("确认删除", isPresented: $showDeleteConfirm) {
      Button("取消", role: .cancel) {}
      Button("删除", role: .destructive) {
        Task {
          updating = true
          do {
            try await Chii.shared.deleteSubjectPost(postId: subreply.id)
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

struct CreateReplyBoxSheet: View {
  let type: TopicParentType
  let topicId: Int
  let reply: ReplyDTO?
  let subreply: ReplyBaseDTO?
  let onSuccess: (() -> Void)?

  @Environment(\.dismiss) private var dismiss

  @State private var content: String = ""
  @State private var token: String = ""
  @State private var showTurnstile: Bool = false
  @State private var updating: Bool = false

  var title: String {
    if let subreply = subreply {
      return "回复 \(subreply.creator?.nickname ?? "用户 \(subreply.creatorID)")"
    } else if let reply = reply {
      return "回复 \(reply.creator?.nickname ?? "用户 \(reply.creatorID)")"
    } else {
      return "添加新回复"
    }
  }

  init(
    type: TopicParentType, topicId: Int, reply: ReplyDTO? = nil, subreply: ReplyBaseDTO? = nil,
    onSuccess: (() -> Void)? = nil
  ) {
    self.type = type
    self.topicId = topicId
    self.reply = reply
    self.subreply = subreply
    self.onSuccess = onSuccess
  }

  func postReply(content: String) async {
    do {
      updating = true
      var content = content
      if let subreply = subreply {
        let quoteUser = subreply.creator?.nickname ?? "用户 \(subreply.creatorID)"
        let quoteContent = try BBCode().plain(subreply.content)
        let quote = "[quote][b]\(quoteUser)[/b]说: \(quoteContent)[/quote]\n"
        content = quote + content
      }
      try await type.reply(topicId: topicId, content: content, replyTo: reply?.id, token: token)
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

struct EditReplyBoxSheet: View {
  let type: TopicParentType
  let topicId: Int
  let reply: ReplyDTO?
  let subreply: ReplyBaseDTO?
  let onSuccess: (() -> Void)?

  @Environment(\.dismiss) private var dismiss

  @State private var content: String
  @State private var updating: Bool = false

  init(
    type: TopicParentType, topicId: Int, reply: ReplyDTO? = nil, subreply: ReplyBaseDTO? = nil,
    onSuccess: (() -> Void)? = nil
  ) {
    self.type = type
    self.topicId = topicId
    self.reply = reply
    self.subreply = subreply
    self.onSuccess = onSuccess
    _content = State(initialValue: subreply?.content ?? reply?.content ?? "")
  }

  func editReply(content: String) async {
    do {
      updating = true
      let postId: Int
      if let subreply = subreply {
        postId = subreply.id
      } else if let reply = reply {
        postId = reply.id
      } else {
        Notifier.shared.alert(message: "找不到要编辑的回复")
        return
      }
      try await type.editPost(postId: postId, content: content)
      Notifier.shared.notify(message: "编辑成功")
      onSuccess?()
      dismiss()
    } catch {
      Notifier.shared.alert(error: error)
    }
    updating = false
  }

  var title: String {
    if subreply != nil {
      return "编辑回复"
    } else if reply != nil {
      return "编辑回复"
    } else {
      return "编辑"
    }
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
                await editReply(content: content)
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

struct CreateTopicBoxSheet: View {
  let type: TopicParentType
  let onSuccess: (() -> Void)?

  @Environment(\.dismiss) private var dismiss

  @State private var title: String = ""
  @State private var content: String = ""
  @State private var token: String = ""
  @State private var showTurnstile: Bool = false
  @State private var updating: Bool = false

  init(type: TopicParentType, onSuccess: (() -> Void)? = nil) {
    self.type = type
    self.onSuccess = onSuccess
  }

  func createTopic(title: String, content: String, token: String) async {
    do {
      try await type.createTopic(title: title, content: content, token: token)
      Notifier.shared.notify(message: "创建成功")
      onSuccess?()
      dismiss()
    } catch {
      Notifier.shared.alert(error: error)
    }
  }

  var header: String {
    switch type {
    case .subject:
      return "创建条目讨论"
    case .group:
      return "创建小组话题"
    }
  }

  var body: some View {
    NavigationStack {
      ScrollView {
        VStack {
          BorderView(color: .secondary.opacity(0.2), padding: 4) {
            TextField("标题", text: $title)
              .textInputAutocapitalization(.never)
              .disableAutocorrection(true)
              .disabled(updating)
          }
          TextInputView(type: "讨论", text: $content)
            .textInputStyle(bbcode: true)
            .disabled(updating)
            .sheet(isPresented: $showTurnstile) {
              TurnstileSheetView(
                token: $token,
                onSuccess: {
                  Task {
                    await createTopic(title: title, content: content, token: token)
                  }
                })
            }
        }.padding()
      }
      .navigationTitle(header)
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
            .disabled(title.isEmpty || content.isEmpty)
          }
        }
      }
    }
  }
}

struct EditTopicBoxSheet: View {
  let type: TopicParentType
  let topicId: Int
  let post: ReplyDTO?
  let onSuccess: (() -> Void)?

  @Environment(\.dismiss) private var dismiss

  @State private var title: String
  @State private var content: String
  @State private var updating: Bool = false

  init(
    type: TopicParentType, topicId: Int, title: String, post: ReplyDTO? = nil,
    onSuccess: (() -> Void)? = nil
  ) {
    self.type = type
    self.topicId = topicId
    self.onSuccess = onSuccess
    self._title = State(initialValue: title)
    if let post = post {
      self.post = post
      self._content = State(initialValue: post.content)
    } else {
      self.post = nil
      self._content = State(initialValue: "")
    }
  }

  func editTopic(title: String, content: String) async {
    do {
      updating = true
      try await type.editTopic(topicId: topicId, title: title, content: content)
      Notifier.shared.notify(message: "编辑成功")
      onSuccess?()
      dismiss()
    } catch {
      Notifier.shared.alert(error: error)
    }
    updating = false
  }

  var header: String {
    switch type {
    case .subject:
      return "编辑条目讨论"
    case .group:
      return "编辑小组话题"
    }
  }

  var submitDisabled: Bool {
    if post == nil {
      return false
    }
    return title.isEmpty || content.isEmpty
  }

  var body: some View {
    NavigationStack {
      ScrollView {
        VStack {
          if post == nil {
            ZStack {
              VStack(alignment: .leading) {
                Text("找不到对应的内容，请检查 topic 并重新编辑")
                  .font(.callout.bold())
                  .foregroundStyle(.red)
              }
              RoundedRectangle(cornerRadius: 5)
                .stroke(.accent, lineWidth: 1)
                .padding(.horizontal, 1)
            }
          }
          BorderView(color: .secondary.opacity(0.2), padding: 4) {
            TextField("标题", text: $title)
              .textInputAutocapitalization(.never)
              .disableAutocorrection(true)
              .disabled(updating)
          }
          TextInputView(type: "讨论", text: $content)
            .textInputStyle(bbcode: true)
            .disabled(updating)
        }.padding()
      }
      .navigationTitle(header)
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
                await editTopic(title: title, content: content)
              }
            } label: {
              Label("保存", systemImage: "checkmark")
            }
            .disabled(submitDisabled)
          }
        }
      }
    }
  }
}

struct MainPostContentView: View {
  let type: TopicParentType
  let topicId: Int
  let idx: Int
  let reply: ReplyDTO
  let author: SlimUserDTO?
  @Binding var reactions: [ReactionDTO]

  @AppStorage("friendlist") var friendlist: [Int] = []
  @AppStorage("anonymizeTopicUsers") var anonymizeTopicUsers: Bool = false

  init(
    type: TopicParentType, topicId: Int, idx: Int, reply: ReplyDTO, author: SlimUserDTO?,
    reactions: Binding<[ReactionDTO]>
  ) {
    self.type = type
    self.topicId = topicId
    self.idx = idx
    self.reply = reply
    self.author = author
    self._reactions = reactions
  }

  var anonymizedHash: String {
    AnonymizationHelper.generateHash(topicId: topicId, userId: reply.creatorID)
  }

  var anonymizedColor: Color {
    AnonymizationHelper.generateColor(from: anonymizedHash)
  }

  var body: some View {
    VStack(alignment: .leading) {
      HStack(alignment: .top) {
        if anonymizeTopicUsers {
          if let creator = reply.creator {
            Rectangle()
              .fill(anonymizedColor)
              .frame(width: 40, height: 40)
              .clipShape(Circle())
              .imageLink(creator.link)
          } else {
            Rectangle()
              .fill(anonymizedColor)
              .frame(width: 40, height: 40)
              .clipShape(Circle())
          }
        } else if let creator = reply.creator {
          ImageView(img: creator.avatar?.large)
            .imageStyle(width: 40, height: 40)
            .imageType(.avatar)
            .imageLink(creator.link)
        } else {
          Rectangle().fill(.clear).frame(width: 40, height: 40)
        }
        VStack(alignment: .leading) {
          VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 4) {
              PosterLabel(uid: reply.creatorID, poster: author?.id)
              FriendLabel(uid: reply.creatorID)
              if anonymizeTopicUsers {
                if let creator = reply.creator {
                  Text(anonymizedHash.withLink(creator.link)).lineLimit(1)
                } else {
                  Text(anonymizedHash).lineLimit(1)
                }
              } else if let creator = reply.creator {
                Text(creator.nickname.withLink(creator.link)).lineLimit(1)
              } else {
                Text("用户 \(reply.creatorID)")
                  .lineLimit(1)
              }
            }
            Text("#\(idx+1) - \(reply.createdAt.datetimeDisplay)")
              .lineLimit(1)
              .font(.footnote)
              .foregroundStyle(.secondary)
          }
          BBCodeView(reply.content)
            .tint(.linkText)
            .textSelection(.enabled)
            .fixedSize(horizontal: false, vertical: true)
          if !reactions.isEmpty {
            switch type {
            case .subject:
              ReactionsView(type: .subjectReply(reply.id), reactions: $reactions)
            case .group:
              ReactionsView(type: .groupReply(reply.id), reactions: $reactions)
            }
          }
          ForEach(Array(zip(reply.replies.indices, reply.replies)), id: \.1) { subidx, subreply in
            VStack(alignment: .leading) {
              Divider()
              switch subreply.state {
              case .normal:
                SubReplyNormalView(
                  type: type, idx: idx, reply: reply, subidx: subidx, subreply: subreply,
                  author: author, topicId: topicId)
              case .userDelete, .adminOffTopic, .adminCloseTopic, .adminReopen, .adminSilentTopic:
                PostTopicActionStateView(
                  topicId, subreply.state, subreply.creatorID, subreply.creator, subreply.createdAt, author)
              default:
                PostStateView(subreply.state)
              }
            }.blocklistFilter(subreply.creatorID)
          }
        }
      }
    }
  }
}
