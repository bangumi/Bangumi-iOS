import SwiftData
import SwiftUI

struct EpisodeItemView: View {
  @Environment(Episode.self) var episode

  var body: some View {
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
      .padding(2)
      .contextMenu {
        EpisodeUpdateMenu().environment(episode)
      } preview: {
        EpisodeInfoView()
          .environment(episode)
          .padding()
          .frame(idealWidth: 360)
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
      EpisodeItemView().environment(episodes.first!)
        .modelContainer(container)
    }.padding()
  }
}
