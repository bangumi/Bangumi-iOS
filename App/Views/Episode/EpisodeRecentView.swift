import Flow
import OSLog
import SwiftData
import SwiftUI

enum EpisodeRecentMode {
  case tile
  case list
}

struct EpisodeRecentView: View {
  let subjectId: Int
  let mode: EpisodeRecentMode

  @Environment(Subject.self) var subject
  @Environment(\.modelContext) var modelContext

  @Query private var episodes: [Episode] = []

  var nextEpisode: Episode? {
    episodes.first { $0.status == EpisodeCollectionType.none.rawValue }
  }

  var progressText: String {
    return "\(subject.interest?.epStatus ?? 0) / \(subject.eps)"
  }

  var progressIcon: String {
    return "square.grid.2x2.fill"
  }

  var recentEpisodes: [Episode] {
    let idx = episodes.firstIndex { $0.status == EpisodeCollectionType.none.rawValue }
    if let idx = idx {
      if idx < 3 {
        return Array(episodes.prefix(5))
      } else if idx < episodes.count - 3 {
        return Array(episodes[idx - 2..<min(idx + 3, episodes.count)])
      } else {
        return Array(episodes.suffix(5))
      }
    } else {
      if let first = episodes.first {
        if first.status == EpisodeCollectionType.none.rawValue {
          return Array(episodes.prefix(5))
        } else {
          return Array(episodes.suffix(5))
        }
      } else {
        return []
      }
    }
  }

  init(subjectId: Int, mode: EpisodeRecentMode) {
    self.subjectId = subjectId
    self.mode = mode

    let descriptor = FetchDescriptor<Episode>(
      predicate: #Predicate<Episode> {
        $0.subjectId == subjectId && $0.type == 0
      }, sortBy: [SortDescriptor<Episode>(\.sort, order: .forward)])

    _episodes = Query(descriptor)
  }

  var body: some View {
    switch mode {
    case .tile:
      VStack(alignment: .leading) {
        if !recentEpisodes.isEmpty {
          HStack(spacing: 2) {
            ForEach(recentEpisodes) { episode in
              EpisodeItemView()
                .environment(episode)
            }
          }.font(.footnote)
        }
        HStack {
          Spacer()
          if let episode = nextEpisode {
            EpisodeNextView()
              .environment(episode)
          } else {
            NavigationLink(value: NavDestination.subject(subjectId)) {
              Label(progressText, systemImage: progressIcon)
                .labelStyle(.compact)
                .foregroundStyle(.secondary)
            }.buttonStyle(.scale)
          }
        }
      }
      .animation(.default, value: nextEpisode)
      .animation(.default, value: recentEpisodes)
    case .list:
      HStack {
        if !recentEpisodes.isEmpty {
          HStack(spacing: 2) {
            ForEach(recentEpisodes) { episode in
              EpisodeItemView()
                .environment(episode)
            }
          }.font(.footnote)
          Spacer(minLength: 0)
          if let episode = nextEpisode {
            EpisodeNextView()
              .environment(episode)
          } else {
            NavigationLink(value: NavDestination.subject(subjectId)) {
              Label(progressText, systemImage: progressIcon)
                .labelStyle(.compact)
                .foregroundStyle(.secondary)
            }.buttonStyle(.scale)
          }
        } else {
          NavigationLink(value: NavDestination.subject(subjectId)) {
            Label(progressText, systemImage: progressIcon)
              .foregroundStyle(.secondary)
          }.buttonStyle(.scale)
        }
      }
      .animation(.default, value: nextEpisode)
      .animation(.default, value: recentEpisodes)
    }
  }
}

struct EpisodeNextView: View {
  @Environment(Episode.self) var episode

  @State private var updating: Bool = false

  var buttonText: String {
    return "EP.\(episode.sort.episodeDisplay) 看过"
  }

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

  var body: some View {
    if !episode.aired {
      Text("EP.\(episode.sort.episodeDisplay) ~ \(episode.waitDesc)")
        .foregroundStyle(.secondary)
    } else {
      if updating {
        ZStack {
          Button(buttonText, action: {})
            .disabled(true)
            .hidden()
          ProgressView()
        }
      } else {
        Button {
          updateSingle(episode: episode, type: .collect)
        } label: {
          Label(buttonText, systemImage: "checkmark.circle")
            .labelStyle(.compact)
        }
      }
    }
  }
}
