import BBCode
import SwiftUI

enum TopicParentType {
  case subject
  case group
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
    case .userDelete:
      ReplyUserDeleteView(idx: idx, reply: reply.base, author: author)
    default:
      Text(reply.state.description)
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
  @AppStorage("shareDomain") var shareDomain: ShareDomain = .chii

  @State private var showReplyBox: Bool = false
  @State private var showEditBox: Bool = false
  @State private var updating: Bool = false
  @State private var showDeleteConfirm: Bool = false

  var shareLink: URL {
    URL(
      string:
        "https://\(shareDomain.rawValue)/\(type)/topic/\(topicId)#post_\(reply.id)")!
  }

  var body: some View {
    VStack(alignment: .leading) {
      HStack(alignment: .top) {
        if let creator = reply.creator {
          ImageView(img: creator.avatar?.large)
            .imageStyle(width: 40, height: 40)
            .imageType(.avatar)
            .imageLink(creator.link)
        } else {
          Rectangle().fill(.clear).frame(width: 40, height: 40)
        }
        VStack(alignment: .leading) {
          HStack {
            if let creator = reply.creator, let author = author {
              if creator.id == author.id {
                BorderView {
                  Text("楼主")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }
              }
              Text(creator.header).lineLimit(1)
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
              ShareLink(item: shareLink) {
                Label("分享", systemImage: "square.and.arrow.up")
              }
            } label: {
              Text("#\(idx+1) - \(reply.createdAt.datetimeDisplay)")
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
          ForEach(Array(zip(reply.replies.indices, reply.replies)), id: \.1) { subidx, subreply in
            VStack(alignment: .leading) {
              Divider()
              switch subreply.state {
              case .normal:
                SubReplyNormalView(
                  type: type, idx: idx, reply: reply, subidx: subidx, subreply: subreply,
                  author: author, topicId: topicId)
              case .userDelete:
                ReplyUserDeleteView(idx: subidx, reply: subreply, author: author)
              default:
                Text(subreply.state.description)
              }
            }
          }
        }
      }
      .sheet(isPresented: $showReplyBox) {
        ReplyBoxView(type: type, topicId: topicId, reply: idx == 0 ? nil : reply)
          .presentationDetents([.large])
      }
      .sheet(isPresented: $showEditBox) {
        ReplyBoxView(type: type, topicId: topicId, reply: reply, isEdit: true)
          .presentationDetents([.large])
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

struct ReplyUserDeleteView: View {
  let idx: Int
  let reply: ReplyBaseDTO
  let author: SlimUserDTO?

  var body: some View {
    HStack {
      if let creator = reply.creator, let author = author {
        if creator.id == author.id {
          BorderView {
            Text("楼主")
              .font(.caption)
              .foregroundStyle(.secondary)
          }
        }
        Text(creator.nickname.withLink(creator.link)).lineLimit(1)
      } else {
        Text("用户 \(reply.creatorID)")
          .lineLimit(1)
      }
      Text("删除了回复")
        .font(.footnote)
        .foregroundStyle(.secondary)
      Spacer()
      Text(reply.createdAt.datetimeDisplay)
        .lineLimit(1)
        .font(.caption)
        .foregroundStyle(.secondary)
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
  @AppStorage("shareDomain") var shareDomain: ShareDomain = .chii

  @State private var showReplyBox: Bool = false
  @State private var showEditBox: Bool = false
  @State private var updating: Bool = false
  @State private var showDeleteConfirm: Bool = false

  var shareLink: URL {
    URL(string: "https://\(shareDomain.rawValue)/\(type)/topic/\(reply.id)#post_\(subreply.id)")!
  }

  var body: some View {
    HStack(alignment: .top) {
      if let creator = subreply.creator {
        ImageView(img: creator.avatar?.large)
          .imageStyle(width: 40, height: 40)
          .imageType(.avatar)
          .imageLink(creator.link)
      } else {
        Rectangle().fill(.clear).frame(width: 40, height: 40)
      }
      VStack(alignment: .leading) {
        HStack {
          if let creator = subreply.creator, let author = author {
            if creator.id == author.id {
              BorderView {
                Text("楼主")
                  .font(.caption)
                  .foregroundStyle(.secondary)
              }
            }
            Text(creator.nickname.withLink(creator.link))
              .lineLimit(1)
          } else {
            Text("用户 \(subreply.creatorID)")
              .lineLimit(1)
          }
          Spacer()
          Menu {
            Button {
              showReplyBox = true
            } label: {
              Text("回复")
            }
            if subreply.creatorID == profile.id {
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
            ShareLink(item: shareLink) {
              Label("分享", systemImage: "square.and.arrow.up")
            }
          } label: {
            Text("#\(idx+1)-\(subidx+1) - \(subreply.createdAt.datetimeDisplay)")
              .lineLimit(1)
              .font(.caption)
              .foregroundStyle(.secondary)
            Image(systemName: "ellipsis")
              .foregroundStyle(.secondary)
          }.buttonStyle(.plain)
        }
        BBCodeView(subreply.content)
          .tint(.linkText)
          .textSelection(.enabled)
      }
    }
    .sheet(isPresented: $showReplyBox) {
      ReplyBoxView(type: type, topicId: topicId, reply: reply, subreply: subreply)
        .presentationDetents([.large])
    }
    .sheet(isPresented: $showEditBox) {
      ReplyBoxView(type: type, topicId: topicId, reply: reply, subreply: subreply, isEdit: true)
        .presentationDetents([.large])
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

struct ReplyBoxView: View {
  let type: TopicParentType
  let topicId: Int
  let reply: ReplyDTO?
  let subreply: ReplyBaseDTO?
  let isEdit: Bool

  @Environment(\.dismiss) private var dismiss

  @State private var content: String = ""
  @State private var token: String = ""
  @State private var updating: Bool = false

  init(
    type: TopicParentType, topicId: Int, reply: ReplyDTO? = nil, subreply: ReplyBaseDTO? = nil,
    isEdit: Bool = false
  ) {
    self.type = type
    self.topicId = topicId
    self.reply = reply
    self.subreply = subreply
    self.isEdit = isEdit
    if isEdit {
      _content = State(initialValue: subreply?.content ?? reply?.content ?? "")
    }
  }

  func postReply(content: String) async {
    do {
      updating = true
      var content = content
      if !isEdit, let subreply = subreply {
        let quoteUser = subreply.creator?.nickname ?? "用户 \(subreply.creatorID)"
        let quoteContent = try BBCode().plain(subreply.content)
        let quote = "[quote][b]\(quoteUser)[/b]说: \(quoteContent)[/quote]\n"
        content = quote + content
      }
      if isEdit {
        let postId: Int
        if let subreply = subreply {
          postId = subreply.id
        } else if let reply = reply {
          postId = reply.id
        } else {
          Notifier.shared.alert(message: "找不到要编辑的回复")
          return
        }
        try await Chii.shared.editSubjectPost(postId: postId, content: content)
      } else {
        try await Chii.shared.createSubjectReply(
          topicId: topicId, content: content,
          replyTo: reply?.id, token: token)
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
      if subreply != nil {
        return "编辑回复"
      } else if reply != nil {
        return "编辑回复"
      } else {
        return "编辑"
      }
    } else {
      if let subreply = subreply {
        return "回复 \(subreply.creator?.nickname ?? "用户 \(subreply.creatorID)")"
      } else if let reply = reply {
        return "回复 \(reply.creator?.nickname ?? "用户 \(reply.creatorID)")"
      } else {
        return "添加新回复"
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
          .disabled(content.isEmpty || (!isEdit && token.isEmpty) || updating)
          .buttonStyle(.borderedProminent)
        }
        TextInputView(type: isEdit ? "内容" : "回复", text: $content)
          .textInputStyle(bbcode: true)
        if !isEdit {
          TrunstileView(token: $token).frame(height: 65)
        }
      }.padding()
    }
  }
}
