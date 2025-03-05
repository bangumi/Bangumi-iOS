import Flow
import OSLog
import SwiftData
import SwiftUI

struct EpisodeRecentView: View {
  let subjectId: Int

  @AppStorage("isolationMode") var isolationMode: Bool = false

  @Environment(Subject.self) var subject
  @Environment(\.modelContext) var modelContext

  @State private var updating: Bool = false

  @Query private var episodes: [Episode] = []

  var nextEpisode: Episode? {
    episodes.first { $0.status == EpisodeCollectionType.none.rawValue }
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

  init(subjectId: Int) {
    self.subjectId = subjectId

    let descriptor = FetchDescriptor<Episode>(
      predicate: #Predicate<Episode> {
        $0.subjectId == subjectId && $0.type == 0
      }, sortBy: [SortDescriptor<Episode>(\.sort, order: .forward)])

    _episodes = Query(descriptor)
  }

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

  var body: some View {
    VStack(alignment: .leading) {
      HStack(spacing: 2) {
        ForEach(recentEpisodes) { episode in
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
      }.font(.callout)

      HStack {
        Spacer()
        if let episode = nextEpisode {
          if episode.air > Date() {
            Text("EP.\(episode.sort.episodeDisplay) ~ \(episode.waitDesc)")
              .foregroundStyle(.secondary)
          } else {
            if updating {
              ZStack {
                Button("看过", action: {})
                  .disabled(true)
                  .hidden()
                ProgressView()
              }
            } else {
              Button {
                updateSingle(episode: episode, type: .collect)
              } label: {
                Label(
                  "EP.\(episode.sort.episodeDisplay) 看过", systemImage: "checkmark.circle")
              }
            }
          }
        } else {
          NavigationLink(value: NavDestination.subject(subjectId)) {
            Label(
              "\(subject.interest?.epStatus ?? 0) / \(subject.eps)",
              systemImage: "square.grid.2x2.fill"
            )
            .labelStyle(.compact)
            .foregroundStyle(.secondary)
          }.buttonStyle(.scale)
        }
      }
    }.animation(.default, value: episodes)
  }
}

struct EpisodeRecentSlimView: View {
  let subjectId: Int

  @Environment(Subject.self) var subject
  @Environment(\.modelContext) var modelContext

  @State private var updating: Bool = false

  @Query private var pendingEpisodes: [Episode]
  private var nextEpisode: Episode? { pendingEpisodes.first }

  init(subjectId: Int) {
    self.subjectId = subjectId
    var descriptor = FetchDescriptor<Episode>(
      predicate: #Predicate<Episode> {
        $0.subjectId == subjectId && $0.type == 0 && $0.status == 0
      }, sortBy: [SortDescriptor<Episode>(\.sort, order: .forward)])
    descriptor.fetchLimit = 1
    _pendingEpisodes = Query(descriptor)
  }

  func updateSingle(episode: Episode, type: EpisodeCollectionType) {
    if updating { return }
    updating = true
    Task {
      do {
        try await Chii.shared.updateEpisodeCollection(
          episodeId: episode.episodeId, type: type)
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
      } catch {
        Notifier.shared.alert(error: error)
      }
      updating = false
    }
  }

  var body: some View {
    HStack {
      Text("\(subject.interest?.epStatus ?? 0) / \(subject.eps)")
        .foregroundStyle(.secondary)
      Spacer()
      if let episode = nextEpisode {
        if episode.air > Date() {
          Text("EP.\(episode.sort.episodeDisplay) ~ \(episode.waitDesc)")
            .foregroundStyle(.secondary)
        } else {
          if updating {
            ZStack {
              Button("EP... 看过", action: {})
                .disabled(true)
                .hidden()
              ProgressView()
            }
          } else {
            Button {
              updateSingle(episode: episode, type: .collect)
            } label: {
              Label(
                "EP.\(episode.sort.episodeDisplay) 看过",
                systemImage: "checkmark.circle"
              )
            }
          }
        }
      } else {
        NavigationLink(value: NavDestination.subject(subjectId)) {
          Image(systemName: "square.grid.2x2.fill")
            .foregroundStyle(.secondary)
        }.buttonStyle(.scale)
      }
    }.font(.callout)
  }
}
