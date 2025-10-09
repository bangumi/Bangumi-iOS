import SwiftUI

struct PostStateView: View {
  let state: PostState

  init(_ state: PostState) {
    self.state = state
  }

  var body: some View {
    Text(state.description)
      .padding(.leading, 16)
      .overlay {
        Rectangle()
          .fill(state.color)
          .frame(width: 2)
      }
  }
}

struct PostUserDeleteStateView: View {
  let creatorID: Int
  let creator: SlimUserDTO?
  let createdAt: Int
  let author: SlimUserDTO?

  @AppStorage("friendlist") var friendlist: [Int] = []

  init(_ creatorID: Int, _ creator: SlimUserDTO?, _ createdAt: Int, _ author: SlimUserDTO? = nil) {
    self.creatorID = creatorID
    self.creator = creator
    self.createdAt = createdAt
    self.author = author
  }

  var body: some View {
    HStack(spacing: 4) {
      PosterLabel(uid: creatorID, poster: author?.id)
      FriendLabel(uid: creatorID)
      if let creator = creator {
        Text(creator.nickname.withLink(creator.link)).lineLimit(1)
      } else {
        Text("用户 \(creatorID)")
          .lineLimit(1)
      }
      Text("删除了回复")
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

struct PostAdminOffTopicStateView: View {
  let creatorID: Int
  let creator: SlimUserDTO?
  let createdAt: Int
  let author: SlimUserDTO?

  @AppStorage("friendlist") var friendlist: [Int] = []

  init(_ creatorID: Int, _ creator: SlimUserDTO?, _ createdAt: Int, _ author: SlimUserDTO? = nil) {
    self.creatorID = creatorID
    self.creator = creator
    self.createdAt = createdAt
    self.author = author
  }

  var body: some View {
    HStack(spacing: 4) {
      PosterLabel(uid: creatorID, poster: author?.id)
      FriendLabel(uid: creatorID)
      if let creator = creator {
        Text(creator.nickname.withLink(creator.link)).lineLimit(1)
      } else {
        Text("用户 \(creatorID)")
          .lineLimit(1)
      }
      Text("回复被折叠")
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

struct FilterBlocklist: ViewModifier {
  let uid: Int

  @AppStorage("hideBlocklist") var hideBlocklist: Bool = false
  @AppStorage("blocklist") var blocklist: [Int] = []

  func body(content: Content) -> some View {
    if hideBlocklist, blocklist.contains(uid) {
      Rectangle()
        .fill(
          LinearGradient(
            gradient: Gradient(colors: [Color.secondary, Color.clear]),
            startPoint: .leading,
            endPoint: .trailing)
        )
        .frame(height: 8)
    } else {
      content
    }
  }
}

extension View {
  func filterBlocklist(_ uid: Int) -> some View {
    modifier(FilterBlocklist(uid: uid))
  }
}
