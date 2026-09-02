import SwiftUI

final class EpisodeRenderPayload {
  let episode: EpisodeDTO

  init(_ episode: EpisodeDTO) {
    self.episode = episode
  }
}

struct EpisodeItemView: View {
  let payload: EpisodeRenderPayload
  let interactionMode: EpisodeGridInteractionMode
  let subjectCollectionType: CollectionType
  let isNext: Bool
  var reload: (() async -> Void)? = nil

  @Environment(\.theme) private var theme

  init(
    episode: EpisodeDTO,
    interactionMode: EpisodeGridInteractionMode,
    subjectCollectionType: CollectionType,
    isNext: Bool = false,
    reload: (() async -> Void)? = nil
  ) {
    self.payload = EpisodeRenderPayload(episode)
    self.interactionMode = interactionMode
    self.subjectCollectionType = subjectCollectionType
    self.isNext = isNext
    self.reload = reload
  }

  private var episode: EpisodeDTO {
    payload.episode
  }

  private var cellState: EpisodeCellState {
    switch episode.collectionTypeEnum {
    case .collect:
      return .watched
    case .wish:
      return .wish
    case .dropped:
      return .dropped
    case .none:
      if isNext {
        return .next
      }
      return episode.aired ? .aired : .unaired
    }
  }

  @ViewBuilder
  var badge: some View {
    if theme.isClassic {
      classicBadge
    } else {
      glassBadge
    }
  }

  private var classicBadge: some View {
    let colors = episode.badgeColors
    return Text(verbatim: episode.sort.episodeDisplay)
      .monospacedDigit()
      .lineLimit(1)
      .layoutPriority(1)
      .foregroundStyle(colors.foreground)
      .padding(2)
      .background(colors.background)
      .cornerRadius(2)
      .strikethrough(episode.status == EpisodeCollectionType.dropped.rawValue)
      .overlay {
        RoundedRectangle(cornerRadius: 2)
          .fill(.clear)
          .stroke(colors.border, lineWidth: 1)
      }
      .episodeTrend(episode)
  }

  private var glassBadge: some View {
    let style = theme.episodeCell(cellState)
    let radius = theme.metrics.cellRadius
    return Text(verbatim: episode.sort.episodeDisplay)
      .font(.system(.caption, design: .monospaced).weight(.bold))
      .lineLimit(1)
      .layoutPriority(1)
      .foregroundStyle(style.foreground)
      .padding(.horizontal, 2)
      .frame(minWidth: 34, minHeight: 34)
      .background {
        RoundedRectangle(cornerRadius: radius, style: .continuous)
          .fill(
            LinearGradient(
              colors: style.fill, startPoint: .topLeading, endPoint: .bottomTrailing))
      }
      .strikethrough(style.strikethrough)
      .overlay {
        RoundedRectangle(cornerRadius: radius, style: .continuous)
          .stroke(style.border, style: strokeStyle(style))
      }
      .episodeTrend(episode)
  }

  private func strokeStyle(_ style: EpisodeCellStyle) -> StrokeStyle {
    if style.dashed {
      return StrokeStyle(lineWidth: style.borderWidth, dash: [4, 3])
    }
    return StrokeStyle(lineWidth: style.borderWidth)
  }

  var menuLabel: some View {
    badge
      .padding(2)
      .layoutPriority(1)
  }

  var body: some View {
    Group {
      switch interactionMode {
      case .contextMenu:
        menuLabel
          .contentShape(.contextMenuPreview, RoundedRectangle(cornerRadius: 4))
          .contextMenu {
            EpisodeUpdateMenu(
              episode: episode,
              subjectCollectionType: subjectCollectionType,
              reload: reload
            )
          } preview: {
            EpisodeInfoView(episode: episode)
              .padding()
              .frame(idealWidth: 360)
          }
      case .menu:
        Menu {
          EpisodeUpdateMenu(
            episode: episode,
            subjectCollectionType: subjectCollectionType,
            reload: reload,
            showsTitle: true
          )
        } label: {
          menuLabel
        }
        .buttonStyle(.plain)
      }
    }
  }
}
