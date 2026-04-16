import SwiftData
import SwiftUI

struct EpisodeItemView: View {
  @AppStorage("episodeGridInteractionMode") var interactionMode: EpisodeGridInteractionMode =
    .menu
  @Bindable var episode: Episode

  var badge: some View {
    Text("\(episode.sort.episodeDisplay)")
      .monospacedDigit()
      .foregroundStyle(episode.textColor)
      .padding(2)
      .background(episode.backgroundColor)
      .cornerRadius(2)
      .strikethrough(episode.status == EpisodeCollectionType.dropped.rawValue)
      .overlay {
        RoundedRectangle(cornerRadius: 2)
          .fill(.clear)
          .stroke(episode.borderColor, lineWidth: 1)
      }
      .episodeTrend(episode)
  }

  var menuLabel: some View {
    badge
      .padding(2)
  }

  var body: some View {
    Group {
      switch interactionMode {
      case .contextMenu:
        menuLabel
          .contentShape(.contextMenuPreview, RoundedRectangle(cornerRadius: 4))
          .contextMenu {
            EpisodeUpdateMenu(episode: episode)
          } preview: {
            EpisodeInfoView(episode: episode)
              .padding()
              .frame(idealWidth: 360)
          }
      case .menu:
        Menu {
          EpisodeUpdateMenu(episode: episode, showsTitle: true)
        } label: {
          menuLabel
        }
        .buttonStyle(.plain)
      }
    }
  }
}

#Preview {
  let container = mockContainer()

  let subject = Subject.previewAnime
  container.mainContext.insert(subject)

  let episodes = Episode.previewAnime
  for episode in episodes {
    container.mainContext.insert(episode)
  }

  return ScrollView {
    LazyVStack {
      EpisodeItemView(episode: episodes.first!)
        .modelContainer(container)
    }.padding()
  }
}
