import SwiftUI

struct GlassEmbedCard<Content: View>: View {
  var padding: CGFloat = 10
  @ViewBuilder var content: Content

  @Environment(\.theme) private var theme

  var body: some View {
    content
      .padding(padding)
      .background {
        RoundedRectangle(cornerRadius: theme.metrics.embedRadius, style: .continuous)
          .fill(theme.embedFill)
          .overlay {
            RoundedRectangle(cornerRadius: theme.metrics.embedRadius, style: .continuous)
              .strokeBorder(theme.embedBorder, lineWidth: 1)
          }
      }
  }
}

struct GlassSubjectEmbed: View {
  @AppStorage("titlePreference") private var titlePreference: TitlePreference = .original

  let subject: SlimSubjectDTO
  var coverWidth: CGFloat = 58
  var subtitle: String? = nil
  var showsRating: Bool = true

  @Environment(\.theme) private var theme

  private var coverHeight: CGFloat {
    subject.type.coverHeight(for: coverWidth)
  }

  private var ratingText: String? {
    guard showsRating, let rating = subject.rating, rating.score > 0 else {
      return nil
    }
    var parts = ["评分 \(rating.score.rateDisplay)"]
    if rating.rank > 0 {
      parts.append("排名 #\(rating.rank)")
    }
    return parts.joined(separator: " · ")
  }

  var body: some View {
    NavigationLink(value: NavDestination.subject(subject.id)) {
      GlassEmbedCard {
        HStack(alignment: .center, spacing: 12) {
          ImageView(img: subject.images?.resize(.r200))
            .imageStyle(
              width: coverWidth, height: coverHeight,
              cornerRadius: theme.metrics.coverRadius
            )
            .imageType(.subject)
            .imageNSFW(subject.nsfw)
          VStack(alignment: .leading, spacing: 4) {
            Text(subject.title(with: titlePreference))
              .font(.subheadline.weight(.bold))
              .foregroundStyle(theme.cardTitle)
              .lineLimit(2)
            if let subtitle, !subtitle.isEmpty {
              Text(subtitle)
                .font(.caption)
                .foregroundStyle(theme.secondaryText)
                .lineLimit(2)
            } else if let alt = subject.subtitle(with: titlePreference), !alt.isEmpty {
              Text(alt)
                .font(.caption)
                .foregroundStyle(theme.secondaryText)
                .lineLimit(1)
            }
            if subtitle == nil, let info = subject.info, !info.isEmpty {
              Text(info)
                .font(.caption)
                .foregroundStyle(theme.tertiaryText)
                .lineLimit(2)
            }
            if let ratingText {
              Text(ratingText)
                .font(.caption.weight(.semibold))
                .foregroundStyle(theme.accentDeep)
                .lineLimit(1)
            }
          }
          .frame(maxWidth: .infinity, alignment: .leading)
        }
      }
    }
    .buttonStyle(.plain)
    .subjectPreview(subject, eps: true)
  }
}

struct GlassCoverWall: View {
  let subjects: [SlimSubjectDTO]
  var limit: Int = 5

  @AppStorage("showNSFWBadge") private var showNSFWBadge: Bool = true

  @Environment(\.theme) private var theme

  private let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 5)

  private var shape: RoundedRectangle {
    RoundedRectangle(cornerRadius: theme.metrics.badgeRadius, style: .continuous)
  }

  var body: some View {
    LazyVGrid(columns: columns, spacing: 8) {
      ForEach(subjects.prefix(limit)) { subject in
        Color.clear
          .aspectRatio(3 / 4, contentMode: .fit)
          .overlay {
            ImageView(img: subject.images?.resize(.r200))
              .imageStyle(cornerRadius: 0, contentMode: .fill)
              .imageType(.subject)
              .frame(maxWidth: .infinity, maxHeight: .infinity)
          }
          .overlay {
            if subject.nsfw, showNSFWBadge {
              ZStack {
                shape.fill(.ultraThinMaterial)
                Text("NSFW")
                  .font(.caption2.weight(.bold))
                  .foregroundStyle(.secondary)
              }
            }
          }
          .clipShape(shape)
          .imageNavLink(subject.link)
          .subjectPreview(subject)
      }
    }
  }
}

struct GlassRenameEmbed: View {
  let before: String
  let after: String

  @Environment(\.theme) private var theme

  init(before: String, after: String) {
    self.before = before
    self.after = after
  }

  var body: some View {
    GlassEmbedCard {
      HStack(spacing: 10) {
        Text(before)
          .font(.subheadline)
          .foregroundStyle(theme.secondaryText)
          .strikethrough()
          .lineLimit(1)
        Image(systemName: "arrow.right")
          .font(.caption.weight(.semibold))
          .foregroundStyle(theme.tertiaryText)
        Text(after)
          .font(.subheadline.weight(.semibold))
          .foregroundStyle(theme.cardTitle)
          .lineLimit(1)
        Spacer(minLength: 0)
      }
    }
  }
}
