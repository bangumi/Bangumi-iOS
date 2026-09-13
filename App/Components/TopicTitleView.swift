import SwiftUI

struct TopicTitleView: View {
  @Environment(\.theme) private var theme

  let title: String
  let replyCount: Int?
  let link: String?
  let showsReplyCount: Bool

  init(
    title: String,
    replyCount: Int?,
    link: String? = nil,
    showsReplyCount: Bool = false
  ) {
    self.title = title
    self.replyCount = replyCount
    self.link = link
    self.showsReplyCount = showsReplyCount
  }

  var body: some View {
    titleText
  }

  private var titleText: Text {
    var text = Text(title.withLink(link))

    if showsReplyCount, let replyCount {
      text =
        text
        + Text(" (+\(replyCount))")
        .font(.footnote)
        .foregroundColor(theme.secondaryText)
    }

    return text
  }
}

struct TopicAgeBadge: View {
  private static let hour = 60 * 60
  private static let day = 24 * hour
  private static let year = 365 * day

  @AppStorage("showTopicAgeBadge") private var showTopicAgeBadge = true

  let createdAt: Int

  var body: some View {
    let now = Int(Date.now.timeIntervalSince1970)
    if showTopicAgeBadge, createdAt > 0, createdAt <= now {
      let elapsed = now - createdAt
      let color = ageColor(elapsed: elapsed)
      Text(ageText(elapsed: elapsed))
        .font(.caption2.weight(.semibold))
        .monospacedDigit()
        .foregroundStyle(color)
        .padding(.horizontal, 5)
        .padding(.vertical, 1)
        .background(color.opacity(0.15), in: Capsule())
    }
  }

  private func ageText(elapsed: Int) -> String {
    if elapsed < Self.hour {
      return "new"
    }
    if elapsed < Self.day {
      return "\(elapsed / Self.hour)h"
    }
    if elapsed < 30 * Self.day {
      return "\(elapsed / Self.day)d"
    }
    if elapsed < Self.year {
      return "\(elapsed / (30 * Self.day))mo"
    }
    return "\(elapsed / Self.year)y"
  }

  private func ageColor(elapsed: Int) -> Color {
    if elapsed < 6 * Self.hour {
      return .green
    }
    if elapsed < Self.day {
      return .teal
    }
    if elapsed < 3 * Self.day {
      return .blue
    }
    if elapsed < Self.year {
      return .cyan
    }
    if elapsed < 3 * Self.year {
      return .indigo
    }
    if elapsed < 10 * Self.year {
      return .brown
    }
    return .gray
  }
}
