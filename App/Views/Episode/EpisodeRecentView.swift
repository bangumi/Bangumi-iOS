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

  @State private var showCollectionBox: Bool = false

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

  var recentCount: Int {
    return 5
  }

  var recentEpisodes: [Episode] {
    let idx = episodes.firstIndex { $0.status == EpisodeCollectionType.none.rawValue }
    if let idx = idx {
      if idx < 3 {
        return Array(episodes.prefix(recentCount))
      } else if idx < episodes.count - 3 {
        return Array(episodes[idx - 2..<min(idx + 3, episodes.count)])
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

  init(subject: Subject, mode: EpisodeRecentMode) {
    self.subject = subject
    self.mode = mode
    let subjectId = subject.subjectId

    let descriptor = FetchDescriptor<Episode>(
      predicate: #Predicate<Episode> {
        $0.subjectId == subjectId && $0.type == 0
      }, sortBy: [SortDescriptor<Episode>(\.sort, order: .forward)])

    _episodes = Query(descriptor)
  }

  var body: some View {
    switch mode {
    case .tile:
      HStack {
        Spacer(minLength: 0)
        VStack(alignment: .trailing, spacing: 4) {
          if !recentEpisodes.isEmpty {
            HStack(spacing: 2) {
              ForEach(recentEpisodes) { episode in
                EpisodeItemView(episode: episode)
              }
            }.font(.footnote)
          }
          HStack {
            if let episode = nextEpisode {
              EpisodeNextView(episode: episode)
            } else {
              Button {
                showCollectionBox = true
              } label: {
                HStack(spacing: 4) {
                  Text(progressText)
                  Image(systemName: progressIcon)
                }.foregroundStyle(.secondary)
              }
              .buttonStyle(.scale)
              .sheet(isPresented: $showCollectionBox) {
                SubjectCollectionBoxView(subject: subject)
              }
            }
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
              EpisodeItemView(episode: episode)
            }
          }.font(.footnote)
          Spacer(minLength: 0)
          if let episode = nextEpisode {
            EpisodeNextView(episode: episode)
          } else {
            Button {
              showCollectionBox = true
            } label: {
              HStack(spacing: 4) {
                Text(progressText)
                Image(systemName: progressIcon)
              }.foregroundStyle(.secondary)
            }
            .buttonStyle(.scale)
            .sheet(isPresented: $showCollectionBox) {
              SubjectCollectionBoxView(subject: subject)
            }
          }
        } else {
          NavigationLink(value: NavDestination.subject(subject.subjectId)) {
            HStack(spacing: 4) {
              Text(progressText)
              Image(systemName: progressIcon)
            }.foregroundStyle(.secondary)
          }.buttonStyle(.scale)
        }
      }
      .animation(.default, value: nextEpisode)
      .animation(.default, value: recentEpisodes)
    }
  }
}

struct EpisodeNextView: View {
  @Bindable var episode: Episode

  @State private var updating: Bool = false

  var buttonText: String {
    return "EP.\(episode.sort.episodeDisplay)"
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
