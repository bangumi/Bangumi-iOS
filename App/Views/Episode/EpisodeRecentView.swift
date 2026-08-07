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
  @State private var loadingEpisodes: Bool = false

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
    5
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

  private func loadEpisodes() {
    guard !loadingEpisodes else { return }
    Task {
      loadingEpisodes = true
      defer { loadingEpisodes = false }
      do {
        try await EpisodeRepository.loadEpisodes(subject.id)
      } catch {
        Notifier.shared.alert(error: error)
      }
    }
  }

  private var actionPresentation: ProgressActionPresentation {
    .standaloneSubtle
  }

  private var progressFraction: Double? {
    guard subject.eps > 0 else { return nil }
    return min(Double(subject.interest?.epStatus ?? 0) / Double(subject.eps), 1)
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
                subjectCollectionType: subject.ctypeEnum,
                reload: reload
              )
            }
            Spacer(minLength: 0)
          }
          .font(.footnote)
          if let episode = recent.nextEpisode {
            EpisodeNextView(episode: episode, fillWidth: true, progress: progressFraction, reload: reload)
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
              .foregroundStyle(.linkText)
              .progressActionLabelStyle(.standaloneSubtle)
              .progressActionFill(progressFraction)
            }
            .progressActionButtonStyle(tint: .secondary)
            .sheet(isPresented: $showCollectionBox) {
              SubjectCollectionBoxView(subjectId: subject.id, initialSubject: subject)
                .onDisappear {
                  Task {
                    await reload?()
                  }
                }
            }
          }
        }
      case .list:
        HStack(alignment: .bottom) {
          HStack(spacing: 2) {
            ForEach(recent.episodes) { episode in
              EpisodeItemView(
                episode: episode,
                interactionMode: interactionMode,
                subjectCollectionType: subject.ctypeEnum,
                reload: reload
              )
            }
          }.font(.footnote)
          Spacer(minLength: 0)
          if let episode = recent.nextEpisode {
            EpisodeNextView(episode: episode, fillWidth: false, progress: progressFraction, reload: reload)
          } else {
            Button {
              showCollectionBox = true
            } label: {
              HStack(spacing: 4) {
                Text(progressText)
                Image(systemName: progressIcon)
              }
              .foregroundStyle(.linkText)
              .progressActionLabelStyle(.standaloneSubtle)
              .progressActionFill(progressFraction)
            }
            .progressActionButtonStyle(tint: .secondary)
            .sheet(isPresented: $showCollectionBox) {
              SubjectCollectionBoxView(subjectId: subject.id, initialSubject: subject)
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
      Button(action: loadEpisodes) {
        ZStack {
          HStack(spacing: 4) {
            Text(progressText)
            Image(systemName: progressIcon)
          }
          .foregroundStyle(.linkText)
          .opacity(loadingEpisodes ? 0 : 1)
          .accessibilityHidden(loadingEpisodes)

          if loadingEpisodes {
            ProgressView()
              .accessibilityLabel("正在加载章节")
          }
        }
        .frame(maxWidth: actionPresentation.isStandalone ? .infinity : nil)
        .progressActionLabelStyle(actionPresentation)
        .progressActionFill(progressFraction)
      }
      .progressActionButtonStyle(tint: .secondary)
      .disabled(loadingEpisodes)
    }
  }
}

struct EpisodeNextView: View {
  let payload: EpisodeRenderPayload
  let fillWidth: Bool
  var progress: Double? = nil
  var reload: (() async -> Void)? = nil

  @State private var updating: Bool = false

  init(
    episode: EpisodeDTO,
    fillWidth: Bool,
    progress: Double? = nil,
    reload: (() async -> Void)? = nil
  ) {
    self.payload = EpisodeRenderPayload(episode)
    self.fillWidth = fillWidth
    self.progress = progress
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
      ZStack {
        EpisodeNextLabel(desc: episodeDesc, icon: episodeIcon)
          .opacity(updating ? 0 : 1)
          .accessibilityHidden(updating)

        if updating {
          ProgressView()
            .accessibilityLabel("正在更新进度")
        }
      }
      .frame(maxWidth: fillWidth ? .infinity : nil)
      .progressActionLabelStyle(.standaloneSubtle)
      .progressActionFill(progress)
    }
    .progressActionButtonStyle(tint: .secondary)
    .disabled(buttonDisabled)
  }
}

private struct EpisodeNextLabel: View {
  let desc: String
  let icon: String

  @Environment(\.isEnabled) private var isEnabled

  var body: some View {
    Label(desc, systemImage: icon)
      .foregroundStyle(isEnabled ? .linkText : .secondary)
  }
}
