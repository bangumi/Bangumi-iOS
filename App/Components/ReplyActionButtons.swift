import SwiftUI

struct ReplyActionButtons: View {
  let onReply: () -> Void
  let reactionType: ReactionType?
  @Binding var reactions: [ReactionDTO]
  let onEdit: (() -> Void)?
  let onDelete: () -> Void
  let onReport: () -> Void
  let shareLink: URL
  let isAuthenticated: Bool
  let isOwner: Bool
  let updating: Bool

  init(
    onReply: @escaping () -> Void,
    reactionType: ReactionType? = nil,
    reactions: Binding<[ReactionDTO]>,
    onEdit: (() -> Void)? = nil,
    onDelete: @escaping () -> Void,
    onReport: @escaping () -> Void,
    shareLink: URL,
    isAuthenticated: Bool,
    isOwner: Bool,
    updating: Bool = false
  ) {
    self.onReply = onReply
    self.reactionType = reactionType
    self._reactions = reactions
    self.onEdit = onEdit
    self.onDelete = onDelete
    self.onReport = onReport
    self.shareLink = shareLink
    self.isAuthenticated = isAuthenticated
    self.isOwner = isOwner
    self.updating = updating
  }

  var body: some View {
    VStack(alignment: .trailing, spacing: 4) {
      HStack(spacing: 4) {
        Button {
          onReply()
        } label: {
          Image(systemName: "quote.bubble")
        }
        .disabled(!isAuthenticated)
        if let reactionType = reactionType {
          ReactionButton(type: reactionType, reactions: $reactions)
        }
        Menu {
          if isOwner, let onEdit = onEdit {
            Button {
              onEdit()
            } label: {
              Label("编辑", systemImage: "pencil")
            }
            Divider()
            Button(role: .destructive) {
              onDelete()
            } label: {
              Label("删除", systemImage: "trash")
            }
            .disabled(updating)
          }
          Divider()
          Button {
            onReport()
          } label: {
            Label("报告疑虑", systemImage: "exclamationmark.triangle")
          }
          .disabled(!isAuthenticated)
          ShareLink(item: shareLink) {
            Label("分享", systemImage: "square.and.arrow.up")
          }
        } label: {
          Image(systemName: "ellipsis")
        }
      }
    }
    .padding(.trailing, 8)
    .buttonStyle(.scale)
    .foregroundStyle(.quaternary)
  }
}
