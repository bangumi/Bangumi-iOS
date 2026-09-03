import SwiftUI

struct SheetFormPadding: ViewModifier {
  @Environment(\.theme) private var theme

  @ViewBuilder
  func body(content: Content) -> some View {
    if theme.isClassic {
      content.padding()
    } else {
      content
        .padding(.horizontal, theme.metrics.screenPadding)
        .padding(.top, GlassForm.topInset)
        .padding(.bottom, theme.metrics.screenPadding)
    }
  }
}

struct CreateCommentBoxSheet: View {
  let type: CommentParentType
  let comment: CommentDTO?
  let reply: CommentBaseDTO?
  let onSuccess: (() -> Void)?

  @Environment(\.dismiss) private var dismiss

  @State private var content = ""
  @State private var token = ""
  @State private var showTurnstile = false
  @State private var updating = false

  private var title: String {
    if let reply {
      return "回复 \(reply.user?.nickname ?? "用户 \(reply.creatorID)")"
    } else if let comment {
      return "回复 \(comment.user.nickname)"
    } else {
      return type.newCommentTitle
    }
  }

  init(
    type: CommentParentType,
    comment: CommentDTO? = nil,
    reply: CommentBaseDTO? = nil,
    onSuccess: (() -> Void)? = nil
  ) {
    self.type = type
    self.comment = comment
    self.reply = reply
    self.onSuccess = onSuccess
  }

  var body: some View {
    SheetView(title: title, closeDisabled: updating) {
      ScrollView {
        TextInputView(type: "回复", text: $content)
          .textInputStyle(bbcode: true)
          .disabled(updating)
          .sheet(isPresented: $showTurnstile) {
            TurnstileSheetView(
              token: $token,
              onSuccess: {
                Task {
                  await postReply()
                }
              }
            )
          }
          .modifier(SheetFormPadding())
      }
    } controls: {
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

  private func postReply() async {
    updating = true
    defer {
      updating = false
    }

    do {
      var submittedContent = content
      if let reply {
        let quoteUser = reply.user?.nickname ?? "用户 \(reply.creatorID)"
        let quoteContent = try BBCode().plain(reply.content)
        submittedContent =
          "[quote][b]\(quoteUser)[/b]说: \(quoteContent)[/quote]\n"
          + submittedContent
      }
      try await type.reply(
        commentId: comment?.id,
        content: submittedContent,
        token: token
      )
      Notifier.shared.notify(message: "回复成功")
      onSuccess?()
      dismiss()
    } catch {
      Notifier.shared.alert(error: error)
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
  @State private var updating = false

  private var title: String {
    if reply != nil {
      return "编辑回复"
    } else if comment != nil {
      return "编辑评论"
    } else {
      return "编辑"
    }
  }

  init(
    type: CommentParentType,
    comment: CommentDTO? = nil,
    reply: CommentBaseDTO? = nil,
    onSuccess: (() -> Void)? = nil
  ) {
    self.type = type
    self.comment = comment
    self.reply = reply
    self.onSuccess = onSuccess
    _content = State(initialValue: reply?.content ?? comment?.content ?? "")
  }

  var body: some View {
    SheetView(title: title, closeDisabled: updating) {
      ScrollView {
        TextInputView(type: "回复", text: $content)
          .textInputStyle(bbcode: true)
          .disabled(updating)
          .modifier(SheetFormPadding())
      }
    } controls: {
      if updating {
        ProgressView()
      } else {
        Button {
          Task {
            await editComment()
          }
        } label: {
          Label("保存", systemImage: "checkmark")
        }
        .disabled(content.isEmpty)
      }
    }
  }

  private func editComment() async {
    let commentID: Int
    if let reply {
      commentID = reply.id
    } else if let comment {
      commentID = comment.id
    } else {
      Notifier.shared.alert(message: "找不到要编辑的评论")
      return
    }

    updating = true
    defer {
      updating = false
    }

    do {
      try await type.edit(commentId: commentID, content: content)
      Notifier.shared.notify(message: "编辑成功")
      onSuccess?()
      dismiss()
    } catch {
      Notifier.shared.alert(error: error)
    }
  }
}
