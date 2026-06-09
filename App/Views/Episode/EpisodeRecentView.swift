import Flow
import OSLog
import SwiftData
import SwiftUI

enum EpisodeRecentMode {
  case tile
  case list
}

struct EpisodeRecentView: View {
  @Bindable var subject: Subject
  let mode: EpisodeRecentMode
  let episodes: [Episode]

  @State private var showCollectionBox: Bool = false

  var nextEpisode: Episode? {
    episodes.first { $0.status == EpisodeCollectionType.none.rawValue }
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

  var recentEpisodes: [Episode] {
    let halfBefore = (recentCount - 1) / 2
    let halfAfter = recentCount - halfBefore - 1
    let idx = episodes.firstIndex { $0.status == EpisodeCollectionType.none.rawValue }
    if let idx = idx {
      if idx <= halfBefore {
        return Array(episodes.prefix(recentCount))
      } else if idx < episodes.count - halfAfter {
        let start = idx - halfBefore
        let end = min(idx + halfAfter + 1, episodes.count)
        return Array(episodes[start..<end])
      } else {
        return Array(episodes.suffix(recentCount))
      }
    } else {
      if let first = episodes.first {
        if first.status == EpisodeCollectionType.none.rawValue {
          return Array(episodes.prefix(recentCount))
        } else {
          return Array(episodes.suffix(recentCount))
        }
      } else {
        return []
      }
    }
  }

  init(subject: Subject, mode: EpisodeRecentMode, episodes: [Episode]) {
    self.subject = subject
    self.mode = mode
    self.episodes = episodes
  }

  var body: some View {
    if !recentEpisodes.isEmpty {
      switch mode {
      case .tile:
        VStack {
          HStack(spacing: 2) {
            ForEach(recentEpisodes) { episode in
              EpisodeItemView(episode: episode)
            }
            Spacer(minLength: 0)
          }
          .font(.footnote)
          if let episode = nextEpisode {
            EpisodeNextView(episode: episode, fillWidth: true)
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
              SubjectCollectionBoxView(subjectId: subject.subjectId)
            }
          }
        }
        .animation(.default, value: nextEpisode)
        .animation(.default, value: recentEpisodes)
      case .list:
        HStack {
          HStack(spacing: 2) {
            ForEach(recentEpisodes) { episode in
              EpisodeItemView(episode: episode)
            }
          }.font(.footnote)
          Spacer(minLength: 0)
          if let episode = nextEpisode {
            EpisodeNextView(episode: episode, fillWidth: false)
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
              SubjectCollectionBoxView(subjectId: subject.subjectId)
            }
          }
        }
        .animation(.default, value: nextEpisode)
        .animation(.default, value: recentEpisodes)
      }
    } else {
      HStack {
        Spacer()
        NavigationLink(value: NavDestination.subject(subject.subjectId)) {
          HStack(spacing: 4) {
            Text(progressText)
            Image(systemName: progressIcon)
          }
        }
        .progressButtonStyle()
      }
    }
  }
}

struct EpisodeNextView: View {
  @Bindable var episode: Episode
  let fillWidth: Bool

  @State private var updating: Bool = false

  func updateSingle(episode: Episode, type: EpisodeCollectionType) {
    if updating { return }
    Task {
      updating = true
      defer { updating = false }
      do {
        try await Chii.shared.updateEpisodeCollection(
          episodeId: episode.episodeId, type: type)
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
