import SwiftUI

struct EpisodeRowView: View {
  @AppStorage("isolationMode") var isolationMode: Bool = false
  @AppStorage("isAuthenticated") var isAuthenticated: Bool = false
  @AppStorage("titlePreference") var titlePreference: TitlePreference = .original

  @Environment(\.theme) private var theme

  let episode: EpisodeDTO
  let subjectCollectionType: CollectionType
  var reload: (() async -> Void)? = nil

  private var cellStyle: EpisodeCellStyle {
    switch episode.collectionTypeEnum {
    case .collect:
      return theme.episodeCell(.watched)
    case .dropped:
      return theme.episodeCell(.dropped)
    case .wish:
      return theme.episodeCell(.wish)
    case .none:
      return theme.episodeCell(episode.aired ? .aired : .unaired)
    }
  }

  private var cellFill: AnyShapeStyle {
    let colors = cellStyle.fill
    if theme.isClassic {
      return AnyShapeStyle(colors.first ?? .clear)
    }
    return AnyShapeStyle(
      LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing))
  }

  var body: some View {
    VStack(alignment: .leading) {
      Text(episode.titleLink(with: titlePreference))
        .font(.headline)
        .lineLimit(1)
      HStack {
        if isAuthenticated && episode.collectionTypeEnum != .none {
          let style = cellStyle
          BorderView(color: style.border, padding: 4) {
            Text("\(episode.collectionTypeEnum.description)")
              .foregroundStyle(style.foreground)
              .font(.footnote)
          }
          .strikethrough(episode.status == EpisodeCollectionType.dropped.rawValue)
          .background {
            RoundedRectangle(cornerRadius: theme.metrics.badgeRadius)
              .fill(cellFill)
          }
        } else {
          Menu {
            EpisodeUpdateMenu(
              episode: episode,
              subjectCollectionType: subjectCollectionType,
              reload: reload
            )
          } label: {
            if episode.typeEnum == .main {
              if episode.aired {
                BorderView(color: .primary, padding: 4) {
                  Text("已播")
                    .foregroundStyle(.primary)
                    .font(.footnote)
                }
              } else {
                BorderView(padding: 4) {
                  Text("未播")
                    .foregroundStyle(.secondary)
                    .font(.footnote)
                }
              }
            } else {
              BorderView(color: .primary, padding: 4) {
                Text(episode.typeEnum.description)
                  .foregroundStyle(.primary)
                  .font(.footnote)
              }
            }
          }.buttonStyle(.scale)
        }
        VStack(alignment: .leading) {
          HStack {
            Label("\(episode.duration)", systemImage: "clock")
            Label("\(episode.airdate)", systemImage: "calendar")
            Spacer()
            if isAuthenticated && episode.collectionTypeEnum != .none, episode.collectedAt > 0 {
              Text(
                "\(episode.collectionTypeEnum.description): \(episode.collectedAt.datetimeDisplay)"
              ).lineLimit(1)
            }
            if !isolationMode {
              Label("+\(episode.comment)", systemImage: "bubble")
            }
          }
          .font(.footnote)
          .foregroundStyle(.secondary)
          ThemedDivider()
        }
        Spacer()
      }
    }
  }
}
