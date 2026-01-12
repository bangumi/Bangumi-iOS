import SwiftUI

struct ProgressSecondLineView: View {
  @AppStorage("progressSecondLineMode") var secondLineMode: ProgressSecondLineMode = .info
  @AppStorage("titlePreference") var titlePreference: TitlePreference = .original
  @AppStorage("progressViewMode") var progressViewMode: ProgressViewMode = .tile

  @Bindable var subject: Subject

  var tagsCount: Int {
    switch progressViewMode {
    case .tile:
      return 3
    case .list:
      return 5
    }
  }

  var infoLine: Int {
    switch progressViewMode {
    case .tile:
      return 2
    case .list:
      return 1
    }
  }

  var body: some View {
    switch secondLineMode {
    case .subtitle:
      if let subtitle = subject.subtitle(with: titlePreference) {
        Text(subtitle)
          .foregroundStyle(.secondary)
          .font(.footnote)
          .lineLimit(1)
      }

    case .category:
      switch progressViewMode {
      case .tile:
        VStack(alignment: .leading, spacing: 4) {
          Label(subject.category, systemImage: subject.typeEnum.icon)
          if !subject.airtime.date.isEmpty {
            Label(subject.airtime.date, systemImage: "calendar")
              .font(.caption)
              .foregroundStyle(.secondary)
              .lineLimit(1)
          }
        }
        .labelStyle(.compact)
        .font(.caption)
        .foregroundStyle(.secondary)
      case .list:
        HStack(spacing: 4) {
          Label(subject.category, systemImage: subject.typeEnum.icon)
          if !subject.airtime.date.isEmpty {
            Label(subject.airtime.date, systemImage: "calendar")
              .font(.caption)
              .foregroundStyle(.secondary)
              .lineLimit(1)
          }
          Spacer()
        }
        .labelStyle(.compact)
        .font(.caption)
        .foregroundStyle(.secondary)
      }

    case .watching:
      let doing = subject.collection.doing
      let collect = subject.collection.collect
      if doing > 0 || collect > 0 {
        Text("\(doing) 人在看 · \(collect) 人看过")
          .foregroundStyle(.secondary)
          .font(.footnote)
      }

    case .ratingRank:
      let rank = subject.rating.rank
      let score = subject.rating.score
      let total = subject.rating.total
      if rank > 0 || score > 0 {
        HStack(spacing: 12) {
          if rank > 0 {
            Text("#\(rank)")
              .foregroundStyle(.secondary)
              .font(.footnote)
          }
          if total > 10 {
            if score > 0 {
              StarsView(score: score, size: 12)
              Text("\(score.rateDisplay)")
                .font(.footnote)
                .foregroundStyle(.orange)
            }
          } else {
            Text("(少于10人评分)")
              .foregroundStyle(.secondary)
              .font(.footnote)
          }
        }
      }

    case .info:
      if !subject.info.isEmpty {
        Text(subject.info)
          .foregroundStyle(.secondary)
          .font(.caption)
          .lineLimit(infoLine)
      }

    case .metaTag:
      let tags = subject.metaTags.prefix(tagsCount)
      if !tags.isEmpty {
        HStack(spacing: 4) {
          ForEach(tags, id: \.self) { tag in
            Text(tag)
              .padding(2)
              .background(.secondary.opacity(0.1))
              .clipShape(RoundedRectangle(cornerRadius: 5))
          }
        }
        .foregroundStyle(.secondary)
        .font(.caption)
      }
    }
  }
}
