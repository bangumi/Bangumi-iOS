import SwiftUI

struct GlassSubjectHeader: View {
  let subject: SubjectDTO
  let onShowRating: () -> Void

  @Environment(\.theme) private var theme

  private var type: SubjectType {
    subject.type
  }

  private var collectStats: String {
    var text = ""
    if subject.collection.doing > 0 {
      text += "\(subject.collection.doing) 人\(CollectionType.doing.description(type))"
    }
    if subject.collection.collect > 0 {
      text += " / \(subject.collection.collect) 人\(CollectionType.collect.description(type))"
    }
    return text
  }

  private var badgeShape: RoundedRectangle {
    RoundedRectangle(cornerRadius: theme.metrics.badgeRadius, style: .continuous)
  }

  var body: some View {
    VStack(alignment: .leading, spacing: theme.metrics.listSpacing) {
      if subject.locked {
        GlassSubjectLockBanner()
      }
      CardView(padding: theme.metrics.cardPadding) {
        VStack(alignment: .leading, spacing: 11) {
          Text(subject.name)
            .font(.title3.weight(.heavy))
            .foregroundStyle(theme.title)
            .multilineTextAlignment(.leading)
            .textSelection(.enabled)
            .frame(maxWidth: .infinity, alignment: .leading)

          HStack(alignment: .top, spacing: 12) {
            cover
            details
          }

          ThemedDivider()
          ratingRow

          if subject.rating.rank > 0, subject.rating.rank < 1000 {
            GlassSubjectRankPill(rank: subject.rating.rank)
          }
        }
      }
    }
  }

  private var cover: some View {
    ImageView(img: subject.images?.resize(.r400))
      .imageStyle(
        width: 104, height: type.coverHeight(for: 104),
        cornerRadius: theme.metrics.coverRadius
      )
      .imageType(.subject)
      .imageNSFW(subject.nsfw)
      .enableImagePreview(
        subject.images?.large, zoomID: ZoomNavigationID(type: .subject, id: subject.id)
      )
      .shadow(color: theme.heroShadow.color, radius: theme.heroShadow.radius, y: theme.heroShadow.y)
  }

  private var details: some View {
    VStack(alignment: .leading, spacing: 7) {
      HStack(spacing: 6) {
        if type != .none {
          GlassTypeBadge(type: type)
        }
        if !subject.platform.typeCN.isEmpty {
          Text(subject.category)
            .font(.caption2.weight(.bold))
            .monospaced()
            .foregroundStyle(theme.secondaryText)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(theme.controlFill, in: badgeShape)
            .overlay {
              badgeShape.strokeBorder(theme.controlBorder, lineWidth: 1)
            }
        }
      }

      if !subject.airtime.date.isEmpty {
        Text("\(subject.airtime.date) 放送")
          .font(.footnote)
          .foregroundStyle(theme.sectionHeader)
          .lineLimit(1)
      }

      Text(subject.nameCN.isEmpty ? subject.name : subject.nameCN)
        .font(.subheadline.weight(.bold))
        .foregroundStyle(theme.cardTitle)
        .multilineTextAlignment(.leading)
        .truncationMode(.middle)
        .lineLimit(2)
        .textSelection(.enabled)

      NavigationLink(value: NavDestination.subjectInfobox(subject.id)) {
        HStack(alignment: .firstTextBaseline, spacing: 4) {
          Text(subject.info)
            .font(.caption)
            .foregroundStyle(theme.tertiaryText)
            .multilineTextAlignment(.leading)
            .lineLimit(2)
          Spacer(minLength: 0)
          Image(systemName: "chevron.right")
            .font(.caption)
            .foregroundStyle(theme.disabled)
        }
      }
      .buttonStyle(.plain)

      if !collectStats.isEmpty {
        Text(collectStats)
          .font(.caption2.weight(.semibold))
          .monospaced()
          .foregroundStyle(theme.placeholder)
          .lineLimit(1)
      }
    }
    .frame(maxWidth: .infinity, alignment: .leading)
  }

  private var ratingRow: some View {
    HStack(spacing: 9) {
      if subject.rating.total > 10 {
        StarsView(score: Float(subject.rating.score), size: 13)
        if subject.rating.score > 0 {
          Text(subject.rating.score.rateDisplay)
            .font(.title3.weight(.heavy))
            .monospaced()
            .foregroundStyle(theme.accentDeep)
        }
        Text("\(subject.rating.total) 人评分")
          .font(.caption)
          .foregroundStyle(theme.tertiaryText)
          .lineLimit(1)
      } else {
        StarsView(score: 0, size: 13)
        Text("少于 10 人评分")
          .font(.caption)
          .foregroundStyle(theme.tertiaryText)
          .lineLimit(1)
      }
      Spacer(minLength: 0)
      distributionButton
    }
  }

  private var distributionButton: some View {
    Button {
      onShowRating()
    } label: {
      HStack(spacing: 5) {
        Image(systemName: "chart.bar.xaxis")
        Text("分布")
      }
      .font(.caption.weight(.bold))
      .foregroundStyle(theme.secondaryText)
      .padding(.horizontal, 11)
      .padding(.vertical, 6)
      .background(
        theme.controlFill,
        in: RoundedRectangle(cornerRadius: theme.metrics.controlRadius, style: .continuous)
      )
      .overlay {
        RoundedRectangle(cornerRadius: theme.metrics.controlRadius, style: .continuous)
          .strokeBorder(theme.controlBorder, lineWidth: 1)
      }
    }
    .buttonStyle(.plain)
    .accessibilityLabel("评分分布")
  }
}

struct GlassSubjectLockBanner: View {
  @Environment(\.theme) private var theme

  var body: some View {
    HStack(alignment: .top, spacing: 9) {
      Image(systemName: "lock.fill")
        .font(.footnote)
        .foregroundStyle(theme.warn)
      VStack(alignment: .leading, spacing: 2) {
        Text("条目已锁定 · 内容可能不符合收录范围，随时可能被移除，暂停接受修改。")
          .font(.caption)
          .foregroundStyle(theme.warn)
          .multilineTextAlignment(.leading)
        Text("同人志等条目及其收藏、讨论、关联内容将会随时被移除")
          .font(.caption2)
          .foregroundStyle(theme.warn.opacity(0.75))
          .multilineTextAlignment(.leading)
      }
      Spacer(minLength: 0)
    }
    .padding(.horizontal, 14)
    .padding(.vertical, 11)
    .background(
      theme.warnFill,
      in: RoundedRectangle(cornerRadius: theme.metrics.embedRadius, style: .continuous)
    )
    .overlay {
      RoundedRectangle(cornerRadius: theme.metrics.embedRadius, style: .continuous)
        .strokeBorder(theme.warn.opacity(0.3), lineWidth: 1)
    }
  }
}

struct GlassSubjectRankPill: View {
  let rank: Int

  @Environment(\.theme) private var theme

  var body: some View {
    HStack(spacing: 8) {
      Image(systemName: "trophy.fill")
        .font(.caption2.weight(.bold))
        .foregroundStyle(theme.rank)
      Text(verbatim: "#\(rank)")
        .font(.caption.weight(.heavy))
        .monospaced()
        .foregroundStyle(theme.rank)
      Text("Bangumi 全站排名")
        .font(.caption)
        .foregroundStyle(theme.warn)
      Spacer(minLength: 0)
    }
    .padding(.horizontal, 12)
    .padding(.vertical, 8)
    .background(
      theme.warnFill,
      in: RoundedRectangle(cornerRadius: theme.metrics.controlRadius, style: .continuous)
    )
    .overlay {
      RoundedRectangle(cornerRadius: theme.metrics.controlRadius, style: .continuous)
        .strokeBorder(theme.rank.opacity(0.25), lineWidth: 1)
    }
  }
}
