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
  var reload: (() async -> Void)? = nil

  init(
    episode: EpisodeDTO,
    interactionMode: EpisodeGridInteractionMode,
    reload: (() async -> Void)? = nil
  ) {
    self.payload = EpisodeRenderPayload(episode)
    self.interactionMode = interactionMode
    self.reload = reload
  }

  private var episode: EpisodeDTO {
    payload.episode
  }

  var badge: some View {
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
            EpisodeUpdateMenu(episode: episode, reload: reload)
          } preview: {
            EpisodeInfoView(episode: episode)
              .padding()
              .frame(idealWidth: 360)
          }
      case .menu:
        Menu {
          EpisodeUpdateMenu(episode: episode, reload: reload, showsTitle: true)
        } label: {
          menuLabel
        }
        .buttonStyle(.plain)
      }
    }
  }
}
