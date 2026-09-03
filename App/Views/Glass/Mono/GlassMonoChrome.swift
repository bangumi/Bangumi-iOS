import SwiftUI

struct GlassMonoFieldRow: View {
  let key: String
  let value: String

  @Environment(\.theme) private var theme

  var body: some View {
    HStack(alignment: .top, spacing: 10) {
      Text(key)
        .font(.system(.caption2, design: .monospaced).weight(.semibold))
        .foregroundStyle(theme.tertiaryText)
        .lineLimit(1)
        .frame(width: 62, alignment: .leading)
      Text(value)
        .font(.caption)
        .foregroundStyle(theme.secondaryText)
        .textSelection(.enabled)
      Spacer(minLength: 0)
    }
  }
}

struct GlassMonoCaption: View {
  let text: String
  var color: Color? = nil

  @Environment(\.theme) private var theme

  var body: some View {
    Text(text)
      .font(.system(.caption2, design: .monospaced).weight(.semibold))
      .foregroundStyle(color ?? theme.tertiaryText)
      .lineLimit(1)
  }
}

enum GlassMonoTagTone {
  case accent
  case neutral
}

struct GlassMonoTag: View {
  let text: String
  var tone: GlassMonoTagTone = .neutral

  @Environment(\.theme) private var theme

  private var foreground: Color {
    tone == .accent ? theme.onTintText : theme.secondaryText
  }

  private var fill: Color {
    tone == .accent ? theme.tint : theme.controlFill
  }

  private var border: Color {
    tone == .accent ? .clear : theme.controlBorder
  }

  var body: some View {
    Text(text)
      .font(.system(.caption2, design: .monospaced).weight(.bold))
      .lineLimit(1)
      .foregroundStyle(foreground)
      .padding(.horizontal, 8)
      .padding(.vertical, 3)
      .background(
        fill,
        in: RoundedRectangle(cornerRadius: theme.metrics.badgeRadius, style: .continuous)
      )
      .overlay {
        RoundedRectangle(cornerRadius: theme.metrics.badgeRadius, style: .continuous)
          .strokeBorder(border, lineWidth: 1)
      }
  }
}

struct GlassMonoSection<Content: View>: View {
  let title: String
  let systemImage: String
  var destination: NavDestination? = nil
  var moreTitle: String = "更多 »"
  var isEmpty: Bool = false
  var emptyTitle: String = "暂无内容"
  var emptyDescription: String = ""
  @ViewBuilder let content: () -> Content

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      ThemedSectionHeader(title, systemImage: systemImage) {
        if let destination, !isEmpty {
          NavigationLink(value: destination) {
            GlassMoreLabel(title: moreTitle)
          }
          .buttonStyle(.plain)
        }
      }
      if isEmpty {
        ThemedEmptyState(
          systemImage: systemImage, title: emptyTitle, description: emptyDescription)
      } else {
        content()
      }
    }
  }
}

struct GlassInfoboxCard: View {
  let title: String
  let infobox: Infobox
  var limit: Int = 6

  @Environment(\.theme) private var theme

  private var items: [InfoboxItem] {
    Array(infobox.prefix(limit))
  }

  private func joined(_ item: InfoboxItem) -> String {
    var parts: [String] = []
    for value in item.values {
      if let key = value.k, !key.isEmpty {
        parts.append(key + ": " + value.v)
      } else {
        parts.append(value.v)
      }
    }
    return parts.joined(separator: " / ")
  }

  @ViewBuilder
  var body: some View {
    if !infobox.isEmpty {
      VStack(alignment: .leading, spacing: 8) {
        ThemedSectionHeader(title, systemImage: "list.bullet.rectangle") {
          NavigationLink(value: NavDestination.infobox(title, infobox)) {
            GlassMoreLabel(title: "详细信息 ›")
          }
          .buttonStyle(.plain)
        }
        CardView(padding: theme.metrics.cardPadding) {
          VStack(alignment: .leading, spacing: 7) {
            ForEach(items) { item in
              GlassMonoFieldRow(key: item.key, value: joined(item))
            }
          }
          .frame(maxWidth: .infinity, alignment: .leading)
        }
      }
    }
  }
}

struct GlassSummaryCard: View {
  let summary: String
  var title: String = "简介"

  @Environment(\.theme) private var theme

  @ViewBuilder
  var body: some View {
    if !summary.isEmpty {
      VStack(alignment: .leading, spacing: 8) {
        ThemedSectionHeader(title, systemImage: "text.alignleft")
        CardView(padding: theme.metrics.cardPadding) {
          BBCodeView(summary, textSize: 14)
            .textSelection(.enabled)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
      }
    }
  }
}

struct GlassMonoPortraitTile: View {
  let image: String?
  let nsfw: Bool
  let isCollected: Bool
  let link: String
  let caption: String
  let title: String
  var footnote: String? = nil

  @Environment(\.theme) private var theme

  var body: some View {
    VStack(spacing: 6) {
      GlassMonoCaption(text: caption, color: theme.onTintText)
      ImageView(img: image)
        .imageStyle(width: 56, height: 56, alignment: .top)
        .imageType(.person)
        .imageNSFW(nsfw)
        .imageCollectedStatus(isCollected)
        .imageNavLink(link)
      Text(title)
        .font(.caption.weight(.bold))
        .foregroundStyle(theme.cardTitle)
        .multilineTextAlignment(.center)
        .truncationMode(.middle)
        .lineLimit(2)
      if let footnote {
        Text(footnote)
          .font(.caption2)
          .foregroundStyle(theme.tertiaryText)
          .lineLimit(1)
      }
    }
    .frame(width: 96)
    .padding(.vertical, 11)
    .padding(.horizontal, 8)
    .background {
      RoundedRectangle(cornerRadius: theme.metrics.embedRadius, style: .continuous)
        .fill(theme.cardFillStrong)
        .overlay {
          RoundedRectangle(cornerRadius: theme.metrics.embedRadius, style: .continuous)
            .strokeBorder(theme.cardBorder, lineWidth: 1)
        }
        .shadow(
          color: theme.cardShadow.color, radius: theme.cardShadow.radius,
          y: theme.cardShadow.y)
    }
  }
}

struct GlassIndexStatItem: Identifiable {
  let id: Int
  let icon: String
  let count: Int
}

struct GlassIndexRow: View {
  let index: SlimIndexDTO

  @Environment(\.theme) private var theme

  private var counts: [GlassIndexStatItem] {
    let stats = index.stats
    let pairs: [(String, Int?)] = [
      (SubjectType.book.icon, stats.subject.book),
      (SubjectType.anime.icon, stats.subject.anime),
      (SubjectType.music.icon, stats.subject.music),
      (SubjectType.game.icon, stats.subject.game),
      (SubjectType.real.icon, stats.subject.real),
      (IndexRelatedCategory.character.icon, stats.character),
      (IndexRelatedCategory.person.icon, stats.person),
      (IndexRelatedCategory.episode.icon, stats.episode),
      (IndexRelatedCategory.blog.icon, stats.blog),
      (IndexRelatedCategory.groupTopic.icon, stats.groupTopic),
      (IndexRelatedCategory.subjectTopic.icon, stats.subjectTopic),
    ]
    var result: [GlassIndexStatItem] = []
    for pair in pairs {
      guard let count = pair.1, count > 0 else { continue }
      result.append(GlassIndexStatItem(id: result.count, icon: pair.0, count: count))
    }
    return result
  }

  private var dates: String {
    "创建 " + index.createdAt.datetimeDisplay + " · 更新 " + index.updatedAt.datetimeDisplay
  }

  var body: some View {
    HStack(spacing: 10) {
      Image(systemName: "list.bullet.rectangle.portrait")
        .font(.footnote.weight(.bold))
        .foregroundStyle(theme.onTintText)
        .frame(width: 34, height: 34)
        .background(
          theme.tint,
          in: RoundedRectangle(cornerRadius: theme.metrics.cellRadius, style: .continuous)
        )
      VStack(alignment: .leading, spacing: 3) {
        Text(index.title)
          .font(.caption.weight(.bold))
          .foregroundStyle(theme.cardTitle)
          .lineLimit(1)
        HStack(spacing: 6) {
          if let user = index.user {
            Text(user.nickname)
              .foregroundStyle(theme.link)
              .lineLimit(1)
          } else if index.private {
            Label("私有", systemImage: "lock")
              .foregroundStyle(theme.tertiaryText)
          }
          Text("收录 \(index.total) 个条目")
            .foregroundStyle(theme.secondaryText)
            .lineLimit(1)
          Spacer(minLength: 0)
        }
        .font(.caption2)
        if !counts.isEmpty {
          HStack(spacing: 6) {
            ForEach(counts) { item in
              Label("\(item.count)", systemImage: item.icon)
            }
          }
          .labelStyle(.compact)
          .font(.caption2)
          .foregroundStyle(theme.tertiaryText)
        }
        GlassMonoCaption(text: dates)
      }
      Spacer(minLength: 0)
      Image(systemName: "chevron.right")
        .font(.caption2.weight(.bold))
        .foregroundStyle(theme.disabled)
    }
    .padding(.vertical, 10)
    .padding(.horizontal, 14)
  }
}

struct GlassIndexCard: View {
  let index: SlimIndexDTO

  var body: some View {
    CardView(padding: 0) {
      NavigationLink(value: NavDestination.index(index.id)) {
        GlassIndexRow(index: index)
      }
      .buttonStyle(.plain)
    }
  }
}

struct GlassIndexRowsCard: View {
  let indexes: [SlimIndexDTO]

  var body: some View {
    CardView(padding: 0) {
      VStack(spacing: 0) {
        ForEach(indexes.indices, id: \.self) { offset in
          NavigationLink(value: NavDestination.index(indexes[offset].id)) {
            GlassIndexRow(index: indexes[offset])
          }
          .buttonStyle(.plain)
          if offset < indexes.count - 1 {
            ThemedDivider().padding(.leading, 58)
          }
        }
      }
    }
  }
}
