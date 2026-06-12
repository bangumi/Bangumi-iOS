import SwiftUI

struct EpisodeTrend: ViewModifier {
  let episode: EpisodeDTO

  @AppStorage("showEpisodeTrends") var showEpisodeTrends: Bool = true

  func body(content: Content) -> some View {
    if showEpisodeTrends {
      content
        .padding(.bottom, 4)
        .overlay(alignment: .bottomLeading) {
          RoundedRectangle(cornerRadius: 4)
            .frame(height: 4)
            .foregroundStyle(episode.trendColor)
        }
    } else {
      content
    }
  }
}

extension View {
  func episodeTrend(_ episode: EpisodeDTO) -> some View {
    modifier(EpisodeTrend(episode: episode))
  }
}
