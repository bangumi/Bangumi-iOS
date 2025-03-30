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
      .border(episode.borderColor, width: 1)
      .episodeTrend(episode)
      .padding(2)
      .strikethrough(episode.status == EpisodeCollectionType.dropped.rawValue)
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
