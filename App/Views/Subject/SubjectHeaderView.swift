import SwiftUI

struct SubjectHeaderView: View {
  let subject: SubjectDTO
  let onShowRating: () -> Void

  @Environment(\.theme) private var theme

  var type: SubjectType {
    subject.type
  }

  var collectStats: String {
    var text = ""
    if subject.collection.doing > 0 {
      text += "\(subject.collection.doing) 人\(CollectionType.doing.description(type))"
    }
    if subject.collection.collect > 0 {
      text += " / \(subject.collection.collect) 人\(CollectionType.collect.description(type))"
    }
    return text
  }

  var body: some View {
    if theme.isClassic {
      content
    } else {
      CardView(role: .strong) {
        content
      }
    }
  }

  private var content: some View {
    VStack(alignment: .leading) {
      if subject.locked {
        SubjectLockView()
      }
      Text(subject.name)
        .font(.title2.bold())
        .multilineTextAlignment(.leading)
        .textSelection(.enabled)
      HStack {
        ImageView(img: subject.images?.resize(.r400))
          .imageStyle(width: 120, height: type.coverHeight(for: 120))
          .imageType(.subject)
          .imageNSFW(subject.nsfw)
          .enableImagePreview(
            subject.images?.large, zoomID: ZoomNavigationID(type: .subject, id: subject.id)
          )
          .padding(4)
          .subjectCoverShadow(theme)
        VStack(alignment: .leading) {
          HStack {
            if type != .none {
              categoryLabel
            }
            if !subject.airtime.date.isEmpty {
              Label(subject.airtime.date, systemImage: "calendar")
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
            }
            Spacer()
          }
          .font(.caption)
          .foregroundStyle(.secondary)

          Spacer()
          if subject.nameCN.isEmpty {
            Text(subject.name)
              .multilineTextAlignment(.leading)
              .truncationMode(.middle)
              .lineLimit(2)
              .textSelection(.enabled)
          } else {
            Text(subject.nameCN)
              .multilineTextAlignment(.leading)
              .truncationMode(.middle)
              .lineLimit(2)
              .textSelection(.enabled)
          }
          Spacer()

          NavigationLink(value: NavDestination.subjectInfobox(subject.id)) {
            HStack {
              Text(subject.info)
                .font(.caption)
                .lineLimit(2)
              Spacer()
              Image(systemName: "chevron.right")
            }
          }
          .buttonStyle(.navigation)
          .padding(.vertical, 4)
          Spacer()

          if !collectStats.isEmpty {
            Text(collectStats)
              .font(.footnote)
              .foregroundStyle(.secondary)
              .lineLimit(1)
          }

          if subject.rating.total > 10 {
            HStack {
              if subject.rating.score > 0 {
                StarsView(score: Float(subject.rating.score), size: 12)
                Text("\(subject.rating.score.rateDisplay)")
                  .foregroundStyle(theme.isClassic ? Color.orange : theme.accentDeep)
                  .font(theme.isClassic ? Font.callout : .callout.monospacedDigit().weight(.heavy))
                Text("(\(subject.rating.total) 人评分)")
                  .foregroundStyle(.secondary)
                  .lineLimit(1)
              }
              Spacer()
              ratingDistributionButton
            }.font(.footnote)
          } else {
            HStack {
              StarsView(score: 0, size: 12)
              Text("(少于 10 人评分)")
                .foregroundStyle(.secondary)
              Spacer()
              ratingDistributionButton
            }.font(.footnote)
          }
        }
      }

      if subject.rating.rank > 0 && subject.rating.rank < 1000 {
        SubjectRankView(rank: subject.rating.rank)
      }
    }
  }

  @ViewBuilder
  private var categoryLabel: some View {
    if theme.isClassic {
      Label(subject.category, systemImage: type.icon)
    } else {
      Label(subject.category, systemImage: type.icon)
        .foregroundStyle(theme.subjectTint(type).text)
        .padding(.vertical, 2)
        .padding(.horizontal, 6)
        .background {
          RoundedRectangle(cornerRadius: theme.metrics.badgeRadius)
            .fill(theme.subjectTint(type).fill)
        }
    }
  }

  private var ratingDistributionButton: some View {
    Button {
      onShowRating()
    } label: {
      Image(systemName: "chart.bar.xaxis")
    }
    .buttonStyle(.borderless)
    .font(.callout)
    .foregroundStyle(theme.link)
    .accessibilityLabel("评分分布")
  }
}

struct SubjectLockView: View {
  @Environment(\.theme) private var theme

  var body: some View {
    ZStack {
      HStack {
        MusumeView(index: 0, width: 40, height: 60)
          .padding(.horizontal, 5)
        VStack(alignment: .leading) {
          Text("条目已锁定")
            .font(.callout.bold())
            .foregroundStyle(theme.accent)
          Text("同人誌，条目及相关收藏、讨论、关联等内容将会随时被移除。")
            .font(.footnote)
            .foregroundStyle(.secondary)
        }
        Spacer()
      }
      RoundedRectangle(cornerRadius: 5)
        .stroke(theme.accent, lineWidth: 1)
        .padding(.horizontal, 1)
    }
  }
}

struct SubjectRankView: View {
  let rank: Int

  @Environment(\.theme) private var theme

  var body: some View {
    BorderView(color: .accent, padding: 5, role: .accent) {
      HStack {
        Spacer()
        Label("Bangumi Ranked:", systemImage: "chart.bar.xaxis")
        Text("#\(rank)")
        Spacer()
      }
      .font(.callout)
      .foregroundStyle(theme.isClassic ? theme.accent : theme.rank)
    }.padding(5)
  }
}

extension View {
  @ViewBuilder
  fileprivate func subjectCoverShadow(_ theme: ThemeTokens) -> some View {
    if theme.isClassic {
      shadow(radius: 4)
    } else {
      shadow(color: theme.heroShadow.color, radius: theme.heroShadow.radius, y: theme.heroShadow.y)
    }
  }
}
