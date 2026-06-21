import SwiftUI

struct EpisodeUpdateMenu: View {
  @AppStorage("isolationMode") var isolationMode: Bool = false
  @AppStorage("isAuthenticated") var isAuthenticated: Bool = false
  @AppStorage("titlePreference") var titlePreference: TitlePreference = .original

  let episode: EpisodeDTO
  let subjectCollectionType: CollectionType
  var reload: (() async -> Void)? = nil
  var showsTitle: Bool = false

  var titleText: String {
    let title = titlePreference.title(name: episode.name, nameCN: episode.nameCN)
    return "\(episode.typeEnum.name).\(episode.sort.episodeDisplay) \(title)"
  }

  func updateSingle(episode: EpisodeDTO, type: EpisodeCollectionType) {
    Task {
      do {
        try await EpisodeRepository.updateEpisodeCollection(
          episodeId: episode.id, type: type)
        await reload?()
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
      } catch {
        Notifier.shared.alert(error: error)
      }
    }
  }

  func updateBatch(episode: EpisodeDTO) {
    Task {
      do {
        try await EpisodeRepository.updateEpisodeCollection(
          episodeId: episode.id, type: .collect, batch: true)
        await reload?()
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
      } catch {
        Notifier.shared.alert(error: error)
      }
    }
  }

  var canUpdateCollection: Bool {
    isAuthenticated && subjectCollectionType != .none
  }

  var body: some View {
    if showsTitle {
      Section {
        Text(titleText)
          .lineLimit(2)
      }
    }
    if canUpdateCollection {
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
    NavigationLink(value: NavDestination.episode(episode.id)) {
      if isolationMode {
        Label("详情...", systemImage: "info")
      } else {
        Label("参与讨论...", systemImage: "bubble")
      }
    }
  }
}
