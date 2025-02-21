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
    case .userDelete:
      ReplyUserDeleteView(idx: idx, reply: reply.base, author: author)
    default:
      ReplyItemNormalView(type: type, topicId: topicId, idx: idx, reply: reply, author: author)
    }
  }
}

struct ReplyItemNormalView: View {
  let type: TopicParentType
  let topicId: Int
  let idx: Int
  let reply: ReplyDTO
  let author: SlimUserDTO?

  @AppStorage("shareDomain") var shareDomain: ShareDomain = .chii

  @State private var showReplyBox: Bool = false

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
              case .userDelete:
                ReplyUserDeleteView(idx: subidx, reply: subreply, author: author)
              default:
                SubReplyNormalView(
                  type: type, topicId: topicId, idx: idx, reply: reply,
                  subidx: subidx, subreply: subreply, author: author)
              }
            }
          }
        }
      }
      .sheet(isPresented: $showReplyBox) {
        ReplyBoxView(type: type, topicId: topicId, reply: idx == 0 ? nil : reply)
          .presentationDetents([.large])
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
  let topicId: Int
  let idx: Int
  let reply: ReplyDTO
  let subidx: Int
  let subreply: ReplyBaseDTO
  let author: SlimUserDTO?

  @State private var showReplyBox: Bool = false

  @AppStorage("shareDomain") var shareDomain: ShareDomain = .chii

  var shareLink: URL {
    URL(string: "https://\(shareDomain.rawValue)/\(type)/topic/\(topicId)#post_\(subreply.id)")!
  }

  var body: some View {
    HStack(alignment: .top) {
      if let user = subreply.creator {
        ImageView(img: user.avatar?.large)
          .imageStyle(width: 40, height: 40)
          .imageType(.avatar)
          .imageLink(user.link)
      } else {
        Rectangle().fill(.clear).frame(width: 40, height: 40)
      }
      VStack(alignment: .leading) {
        HStack {
          if let user = subreply.creator, let author = author {
            if user.id == author.id {
              BorderView {
                Text("楼主")
                  .font(.caption)
                  .foregroundStyle(.secondary)
              }
            }
            Text(user.nickname.withLink(user.link))
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
            Divider()
            ShareLink(item: shareLink) {
              Label("分享", systemImage: "square.and.arrow.up")
            }
          } label: {
            Text("#\(idx + 1)-\(subidx + 1) - \(subreply.createdAt.datetimeDisplay)")
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
  }
}

struct ReplyBoxView: View {
  let type: TopicParentType
  let topicId: Int
  let reply: ReplyDTO?
  let subreply: ReplyBaseDTO?

  @Environment(\.dismiss) private var dismiss

  @State private var content: String = ""
  @State private var token: String = ""
  @State private var updating: Bool = false

  init(
    type: TopicParentType, topicId: Int,
    reply: ReplyDTO? = nil,
    subreply: ReplyBaseDTO? = nil
  ) {
    self.type = type
    self.topicId = topicId
    self.reply = reply
    self.subreply = subreply
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

      switch type {
      case .subject:
        try await Chii.shared.postSubjectTopicReply(
          topicId: topicId, content: content,
          replyTo: reply?.id, token: token)
      case .group:
        try await Chii.shared.postGroupTopicReply(
          topicId: topicId, content: content,
          replyTo: reply?.id, token: token)
      }
      updating = false
      Notifier.shared.notify(message: "回复成功")
      dismiss()
    } catch {
      Notifier.shared.alert(error: error)
    }
  }

  var title: String {
    if let subreply = subreply {
      return "回复 \(subreply.creator?.nickname ?? "用户 \(subreply.creatorID)")"
    } else if let reply = reply {
      return "回复 \(reply.creator?.nickname ?? "用户 \(reply.creatorID)")"
    } else {
      return "添加新回复"
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
