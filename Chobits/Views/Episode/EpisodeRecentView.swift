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

  init(subjectId: Int) {
    self.subjectId = subjectId

    let descriptor = FetchDescriptor<Episode>(
      predicate: #Predicate<Episode> {
        $0.subjectId == subjectId && $0.type == 0
      }, sortBy: [SortDescriptor<Episode>(\.sort, order: .forward)])

    _episodes = Query(descriptor)
  }

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

  func updateSingle(episode: Episode, type: EpisodeCollectionType) {
    if updating { return }
    updating = true
    Task {
      do {
        try await Chii.shared.updateEpisodeCollection(
          subjectId: episode.subjectId, episodeId: episode.episodeId, type: type)
        _ = try await Chii.shared.loadSubject(subjectId)
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
      } catch {
        Notifier.shared.alert(error: error)
      }
      updating = false
    }
  }

  func updateBatch(episode: Episode) {
    if updating { return }
    updating = true
    Task {
      do {
        try await Chii.shared.updateSubjectEpisodeCollection(
          subjectId: subjectId, updateTo: episode.sort, type: .collect)
        _ = try await Chii.shared.loadSubject(subjectId)
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
      } catch {
        Notifier.shared.alert(error: error)
      }
      updating = false
    }
  }

  var body: some View {
    VStack(alignment: .leading) {
      HStack(spacing: 2) {
        ForEach(recentEpisodes) { episode in
          Text("\(episode.sort.episodeDisplay)")
            .foregroundStyle(Color(hex: episode.textColor))
            .padding(2)
            .background(Color(hex: episode.backgroundColor))
            .border(Color(hex: episode.borderColor), width: 1)
            .padding(2)
            .strikethrough(episode.status == EpisodeCollectionType.dropped.rawValue)
            .contextMenu {
              ForEach(episode.collectionTypeEnum.otherTypes()) { type in
                Button {
                  updateSingle(episode: episode, type: type)
                } label: {
                  Label(type.action, systemImage: type.icon)
                }
              }
              Divider()
              Button {
                updateBatch(episode: episode)
              } label: {
                Label("看到", systemImage: "checkmark.rectangle.stack")
              }
              Divider()
              NavigationLink(value: NavDestination.episode(episode.episodeId)) {
                if isolationMode {
                  Label("详情...", systemImage: "info")
                } else {
                  Label("参与讨论...", systemImage: "bubble")
                }
              }
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
          }.buttonStyle(.plain)
        }
      }
    }
    .animation(.default, value: episodes)
  }
}
