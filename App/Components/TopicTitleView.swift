import SwiftUI

struct TopicTitleView: View {
  @AppStorage("showTopicAgeBadge") private var showTopicAgeBadge = true

  let title: String
  let createdAt: Int
  let updatedAt: Int
  let replyCount: Int?
  let link: String?

  init(
    title: String,
    createdAt: Int,
    updatedAt: Int,
    replyCount: Int?,
    link: String? = nil
  ) {
    self.title = title
    self.createdAt = createdAt
    self.updatedAt = updatedAt
    self.replyCount = replyCount
    self.link = link
  }

  var body: some View {
    HStack(alignment: .top, spacing: 4) {
      if showTopicAgeBadge {
        if let badge = ActivityBadge.resolve(
          createdAt: createdAt,
          updatedAt: updatedAt,
          replyCount: replyCount ?? 0
        ) {
          Text(badge.title)
            .font(.caption)
            .fontWeight(.semibold)
            .foregroundStyle(badge.color)
            .padding(.horizontal, 3)
            .padding(.vertical, 1)
            .overlay {
              RoundedRectangle(cornerRadius: 3)
                .stroke(badge.color, lineWidth: 1)
            }
            .padding(.top, 1)
            .accessibilityLabel(badge.accessibilityLabel)
        }
      }
      Text(title.withLink(link))
    }
  }
}

extension TopicTitleView {
  private enum ActivityBadge {
    case newest
    case newToday
    case newRecent
    case grave
    case oldGrave
    case ancientGrave

    private static let hour = 60 * 60
    private static let day = 24 * hour
    private static let year = 365 * day

    static func resolve(
      createdAt: Int,
      updatedAt: Int,
      replyCount: Int,
      now: Int = Int(Date.now.timeIntervalSince1970)
    ) -> Self? {
      guard createdAt > 0, createdAt <= now else {
        return nil
      }

      let topicAge = now - createdAt
      if topicAge <= 6 * hour {
        return .newest
      }
      if topicAge <= day {
        return .newToday
      }
      if topicAge <= 3 * day {
        return .newRecent
      }

      guard
        replyCount > 0,
        updatedAt > createdAt,
        updatedAt <= now,
        now - updatedAt <= 7 * day
      else {
        return nil
      }

      if topicAge >= 10 * year {
        return .ancientGrave
      }
      if topicAge >= 3 * year {
        return .oldGrave
      }
      if topicAge >= year {
        return .grave
      }
      return nil
    }

    var title: LocalizedStringResource {
      switch self {
      case .newest, .newToday, .newRecent:
        "新"
      case .grave, .oldGrave, .ancientGrave:
        "坟"
      }
    }

    var accessibilityLabel: LocalizedStringResource {
      switch self {
      case .newest, .newToday, .newRecent:
        "新帖"
      case .grave, .oldGrave, .ancientGrave:
        "坟帖"
      }
    }

    var color: Color {
      switch self {
      case .newest:
        .green
      case .newToday:
        .teal
      case .newRecent:
        .blue
      case .grave:
        .indigo
      case .oldGrave:
        .brown
      case .ancientGrave:
        .gray
      }
    }
  }
}
