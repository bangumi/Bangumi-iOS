import SwiftUI

/// Displays topic action states (close/reopen/silent) with styled badge, avatar, and description
struct PostTopicActionStateView: View {
  let topicId: Int
  let state: PostState
  let creatorID: Int
  let creator: SlimUserDTO?
  let createdAt: Int
  let author: SlimUserDTO?

  @AppStorage("friendlist") var friendlist: [Int] = []
  @AppStorage("anonymizeTopicUsers") var anonymizeTopicUsers: Bool = false

  init(
    _ topicId: Int = 0,
    _ state: PostState,
    _ creatorID: Int,
    _ creator: SlimUserDTO?,
    _ createdAt: Int,
    _ author: SlimUserDTO? = nil
  ) {
    self.topicId = topicId
    self.state = state
    self.creatorID = creatorID
    self.creator = creator
    self.createdAt = createdAt
    self.author = author
  }

  var anonymizedHash: String {
    AnonymizationHelper.generateHash(topicId: topicId, userId: creatorID)
  }

  var anonymizedColor: Color {
    AnonymizationHelper.generateColor(from: anonymizedHash)
  }

  var body: some View {
    HStack(spacing: 8) {
      // State badge
      if let actionName = state.actionName {
        Text(actionName)
          .font(.footnote.bold())
          .foregroundStyle(.white)
          .padding(.horizontal, 10)
          .padding(.vertical, 5)
          .background(state.color)
          .cornerRadius(4)
      }

      // Avatar
      if anonymizeTopicUsers && topicId != 0 {
        if let creator = creator {
          Rectangle()
            .fill(anonymizedColor)
            .frame(width: 24, height: 24)
            .clipShape(Circle())
            .imageLink(creator.link)
        } else {
          Rectangle()
            .fill(anonymizedColor)
            .frame(width: 24, height: 24)
            .clipShape(Circle())
        }
      } else if let creator = creator {
        ImageView(img: creator.avatar?.large)
          .imageStyle(width: 24, height: 24)
          .imageType(.avatar)
          .imageLink(creator.link)
      }

      // Username + action description
      HStack(spacing: 4) {
        PosterLabel(uid: creatorID, poster: author?.id)
        FriendLabel(uid: creatorID)
        if anonymizeTopicUsers && topicId != 0 {
          if let creator = creator {
            Text(anonymizedHash.withLink(creator.link)).lineLimit(1)
          } else {
            Text(anonymizedHash).lineLimit(1)
          }
        } else if let creator = creator {
          Text(creator.nickname.withLink(creator.link)).lineLimit(1)
        } else {
          Text("用户 \(creatorID)")
            .lineLimit(1)
        }
        if let actionDescription = state.actionDescription {
          Text(actionDescription)
            .font(.footnote)
            .foregroundStyle(.secondary)
        }
      }

      Spacer()

      Text(createdAt.datetimeDisplay)
        .lineLimit(1)
        .font(.caption)
        .foregroundStyle(.secondary)
    }
  }
}
