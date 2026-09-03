import SwiftUI

struct FriendLabel: View {
  let isFriend: Bool

  @Environment(\.theme) private var theme

  var body: some View {
    if isFriend {
      BorderView(color: theme.success, role: .label) {
        Text("好友")
          .font(.caption)
          .foregroundStyle(theme.successText)
      }
    }
  }
}

struct PosterLabel: View {
  let uid: Int
  let poster: Int?

  @Environment(\.theme) private var theme

  private var labelColor: Color {
    theme.isClassic ? .orange : theme.onTintText
  }

  var body: some View {
    if uid == poster {
      BorderView(color: labelColor, role: .accent) {
        Text("楼主")
          .font(.caption)
          .foregroundStyle(labelColor)
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
