import SwiftData
import SwiftUI

struct EpisodeUpdateMenu: View {
  @AppStorage("isolationMode") var isolationMode: Bool = false
  @AppStorage("isAuthenticated") var isAuthenticated: Bool = false

  @Environment(Episode.self) var episode

  func updateSingle(episode: Episode, type: EpisodeCollectionType) {
    Task {
      do {
        try await Chii.shared.updateEpisodeCollection(
          episodeId: episode.episodeId, type: type)
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
      } catch {
        Notifier.shared.alert(error: error)
      }
    }
  }

  func updateBatch(episode: Episode) {
    Task {
      do {
        try await Chii.shared.updateEpisodeCollection(
          episodeId: episode.episodeId, type: .collect, batch: true)
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
      } catch {
        Notifier.shared.alert(error: error)
      }
    }
  }

  var body: some View {
    if isAuthenticated, episode.subject?.ctype ?? 0 != 0 {
      ForEach(episode.collectionTypeEnum.otherTypes()) { type in
        Button {
          updateSingle(episode: episode, type: type)
        } label: {
          Label(type.action, systemImage: type.icon)
        }
      }
      if episode.typeEnum == .main {
        Divider()
        Button {
          updateBatch(episode: episode)
        } label: {
          Label("看到", systemImage: "checkmark.rectangle.stack")
        }
      }
    }
    Divider()
    NavigationLink(value: NavDestination.episode(episode.episodeId)) {
      if isolationMode {
        Label("详情...", systemImage: "info")
      } else {
        Label("参与讨论...", systemImage: "bubble")
      }
    }
  }
}
