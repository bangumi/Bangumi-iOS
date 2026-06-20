import Flow
import OSLog
import SwiftUI

enum EpisodeRecentMode {
  case tile
  case list
}

private struct RecentEpisodes {
  let episodes: [EpisodeDTO]
  let nextEpisode: EpisodeDTO?
}

final class EpisodeRecentPayload {
  let subject: SubjectDTO
  let episodes: [EpisodeDTO]

  init(subject: SubjectDTO, episodes: [EpisodeDTO]) {
    self.subject = subject
    self.episodes = episodes
  }

  init(_ item: ProgressSubjectDTO) {
    self.subject = item.subject
    self.episodes = item.episodes
  }
}

struct EpisodeRecentView: View {
  let payload: EpisodeRecentPayload
  let mode: EpisodeRecentMode
  let interactionMode: EpisodeGridInteractionMode
  var reload: (() async -> Void)? = nil

  @State private var showCollectionBox: Bool = false

  private var subject: SubjectDTO {
    payload.subject
  }

  private var episodes: [EpisodeDTO] {
    payload.episodes
  }

  var progressText: String {
    return "\(subject.interest?.epStatus ?? 0) / \(subject.eps)"
  }

  var progressIcon: String {
    return "square.grid.2x2.fill"
  }

  var recentCount: Int {
    switch mode {
    case .tile: return 5
    case .list: return 7
    }
  }

  private var recentEpisodes: RecentEpisodes {
    let halfBefore = (recentCount - 1) / 2
    let halfAfter = recentCount - halfBefore - 1
    let idx = episodes.firstIndex { $0.status == EpisodeCollectionType.none.rawValue }
    if let idx = idx {
      let nextEpisode = episodes[idx]
      if idx <= halfBefore {
        return RecentEpisodes(
          episodes: Array(episodes.prefix(recentCount)),
          nextEpisode: nextEpisode
        )
      } else if idx < episodes.count - halfAfter {
        let start = idx - halfBefore
        let end = min(idx + halfAfter + 1, episodes.count)
        return RecentEpisodes(
          episodes: Array(episodes[start..<end]),
          nextEpisode: nextEpisode
        )
      } else {
        return RecentEpisodes(
          episodes: Array(episodes.suffix(recentCount)),
          nextEpisode: nextEpisode
        )
      }
    } else {
      if let first = episodes.first {
        if first.status == EpisodeCollectionType.none.rawValue {
          return RecentEpisodes(
            episodes: Array(episodes.prefix(recentCount)),
            nextEpisode: first
          )
        } else {
          return RecentEpisodes(
            episodes: Array(episodes.suffix(recentCount)),
            nextEpisode: nil
          )
        }
      } else {
        return RecentEpisodes(episodes: [], nextEpisode: nil)
      }
    }
  }

  var body: some View {
    let recent = recentEpisodes
    if !recent.episodes.isEmpty {
      switch mode {
      case .tile:
        VStack {
          HStack(spacing: 2) {
            ForEach(recent.episodes) { episode in
              EpisodeItemView(
                episode: episode,
                interactionMode: interactionMode,
                reload: reload
              )
            }
            Spacer(minLength: 0)
          }
          .font(.footnote)
          if let episode = recent.nextEpisode {
            EpisodeNextView(episode: episode, fillWidth: true, reload: reload)
          } else {
            Button {
              showCollectionBox = true
            } label: {
              HStack(spacing: 4) {
                Spacer()
                Text(progressText)
                Image(systemName: progressIcon)
                Spacer()
              }
            }
            .progressButtonStyle()
            .sheet(isPresented: $showCollectionBox) {
              SubjectCollectionBoxView(subjectId: subject.id)
                .onDisappear {
                  Task {
                    await reload?()
                  }
                }
            }
          }
        }
      case .list:
        HStack {
          HStack(spacing: 2) {
            ForEach(recent.episodes) { episode in
              EpisodeItemView(
                episode: episode,
                interactionMode: interactionMode,
                reload: reload
              )
            }
          }.font(.footnote)
          Spacer(minLength: 0)
          if let episode = recent.nextEpisode {
            EpisodeNextView(episode: episode, fillWidth: false, reload: reload)
          } else {
            Button {
              showCollectionBox = true
            } label: {
              HStack(spacing: 4) {
                Text(progressText)
                Image(systemName: progressIcon)
              }
            }
            .progressButtonStyle()
            .sheet(isPresented: $showCollectionBox) {
              SubjectCollectionBoxView(subjectId: subject.id)
                .onDisappear {
                  Task {
                    await reload?()
                  }
                }
            }
          }
        }
      }
    } else {
      NavigationLink(value: NavDestination.subject(subject.id)) {
        HStack(spacing: 4) {
          Text(progressText)
          Image(systemName: progressIcon)
        }
      }
      .progressButtonStyle()
    }
  }
}

struct EpisodeNextView: View {
  let payload: EpisodeRenderPayload
  let fillWidth: Bool
  var reload: (() async -> Void)? = nil

  @State private var updating: Bool = false

  init(
    episode: EpisodeDTO,
    fillWidth: Bool,
    reload: (() async -> Void)? = nil
  ) {
    self.payload = EpisodeRenderPayload(episode)
    self.fillWidth = fillWidth
    self.reload = reload
  }

  private var episode: EpisodeDTO {
    payload.episode
  }

  func updateSingle(episode: EpisodeDTO, type: EpisodeCollectionType) {
    if updating { return }
    Task {
      updating = true
      defer { updating = false }
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

  var buttonDisabled: Bool {
    !episode.aired || updating
  }

  var episodeDesc: String {
    if episode.aired {
      "EP.\(episode.sort.episodeDisplay)"
    } else {
      "EP.\(episode.sort.episodeDisplay) ~ \(episode.waitDesc)"
    }
  }

  var episodeIcon: String {
    episode.aired ? "checkmark.circle" : "hourglass"
  }

  var body: some View {
    Button {
      updateSingle(episode: episode, type: .collect)
    } label: {
      Group {
        if updating {
          ProgressView()
        } else {
          Label(episodeDesc, systemImage: episodeIcon)
        }
      }
      .frame(maxWidth: fillWidth ? .infinity : nil)
    }
    .progressButtonStyle()
    .disabled(buttonDisabled)
  }
}

extension View {
  func progressButtonStyle() -> some View {
    self
      .labelStyle(.compact)
      .font(.caption)
      .tint(.accent)
      .adaptiveButtonStyle(.bordered)
      .buttonBorderShape(.roundedRectangle(radius: 8))
      .controlSize(.mini)
  }
}
