import SwiftUI

struct MainPostActionButtons: View {
  @AppStorage("isAuthenticated") var isAuthenticated: Bool = false

  let onReply: () -> Void
  let onIndex: () -> Void
  let reactionType: ReactionType
  @Binding var reactions: [ReactionDTO]
  let maxReplyCount: Int
  var allowReply: Bool = true

  var body: some View {
    HStack {
      Spacer()

      Button {
        onReply()
      } label: {
        Label {
          if maxReplyCount > 0 {
            Text("\(maxReplyCount)")
              .foregroundStyle(.secondary)
          }
          Text("回复")
        } icon: {
          Image(systemName: "plus.bubble")
        }
        .labelStyle(.compact)
      }
      .disabled(!isAuthenticated || !allowReply)

      Button {
        onIndex()
      } label: {
        Label("收藏", systemImage: "book")
      }
      .disabled(!isAuthenticated)

      ReactionButton(
        type: reactionType,
        reactions: $reactions,
        showLabel: true
      )
    }
    .foregroundStyle(.secondary)
    .controlSize(.small)
    .adaptiveButtonStyle(.bordered)
    .padding(.horizontal, 16)
    .padding(.bottom, 8)
  }
}
