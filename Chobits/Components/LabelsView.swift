import SwiftUI

struct FriendLabel: View {
  let uid: Int

  @AppStorage("friendlist") var friendlist: [Int] = []

  var body: some View {
    if friendlist.contains(uid) {
      BorderView(color: .green) {
        Text("好友")
          .font(.caption)
          .foregroundStyle(.green)
      }
    }
  }
}

struct PosterLabel: View {
  let uid: Int
  let poster: Int?

  var body: some View {
    if uid == poster {
      BorderView(color: .orange) {
        Text("楼主")
          .font(.caption)
          .foregroundStyle(.orange)
      }
    }
  }
}

struct HeartView: View {
  let collected: Bool
  let updating: Bool

  var body: some View {
    if #available(iOS 18.0, *), updating {
      Image(systemName: collected ? "arrow.clockwise.heart.fill" : "arrow.clockwise.heart")
        .foregroundStyle(collected ? .red : .secondary)
        .symbolEffect(.rotate.byLayer.clockwise)
    } else {
      Image(systemName: collected ? "heart.fill" : "heart")
        .foregroundStyle(collected ? .red : .secondary)
    }
  }
}
