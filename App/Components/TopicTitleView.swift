import SwiftUI

struct TopicTitleView: View {
  private static let hour = 60 * 60
  private static let day = 24 * hour
  private static let year = 365 * day

  @AppStorage("showTopicAgeBadge") private var showTopicAgeBadge = true

  @Environment(\.theme) private var theme

  let title: String
  let createdAt: Int
  let replyCount: Int?
  let link: String?
  let showsReplyCount: Bool

  init(
    title: String,
    createdAt: Int,
    replyCount: Int?,
    link: String? = nil,
    showsReplyCount: Bool = false
  ) {
    self.title = title
    self.createdAt = createdAt
    self.replyCount = replyCount
    self.link = link
    self.showsReplyCount = showsReplyCount
  }

  var body: some View {
    let now = Int(Date.now.timeIntervalSince1970)
    var text = Text(title.withLink(link))

    if showTopicAgeBadge, createdAt > 0, createdAt <= now {
      let elapsed = now - createdAt
      text =
        text
        + Text(" [\(ageText(elapsed: elapsed))]")
        .font(.caption)
        .foregroundColor(ageColor(elapsed: elapsed))
    }

    if showsReplyCount, let replyCount {
      text =
        text
        + Text(" (+\(replyCount))")
        .font(.footnote)
        .foregroundColor(theme.secondaryText)
    }

    return text
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
