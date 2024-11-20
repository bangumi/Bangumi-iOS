//
//  ProgressRowView.swift
//  Chobits
//
//  Created by Chuan Chuan on 2024/4/21.
//

import OSLog
import SwiftData
import SwiftUI

struct ProgressRowView: View {
  let subjectId: UInt

  @Environment(\.modelContext) var modelContext

  @State private var updating: Bool = false
  @State private var nextEpisode: Episode?

  @Query
  private var subjects: [Subject]
  private var subject: Subject? { subjects.first }

  @Query
  private var collections: [UserSubjectCollection]
  private var collection: UserSubjectCollection? { collections.first }

  init(subjectId: UInt) {
    self.subjectId = subjectId

    _subjects = Query(
      filter: #Predicate<Subject> {
        $0.subjectId == subjectId
      })
    _collections = Query(
      filter: #Predicate<UserSubjectCollection> {
        $0.subjectId == subjectId
      })
  }

  func loadNextEpisode() async {
    guard let subject = subject else { return }
    switch subject.typeEnum {
    case .anime, .real:
      break
    default:
      return
    }
    let zero: UInt8 = 0
    do {
      var desc = FetchDescriptor<Episode>(
        predicate: #Predicate<Episode> {
          $0.subjectId == subjectId && $0.type == zero && $0.collection == zero
        }, sortBy: [SortDescriptor<Episode>(\.sort, order: .forward)])
      desc.fetchLimit = 1
      let episodes = try modelContext.fetch(desc)
      if let episode = episodes.first {
        nextEpisode = episode
      } else {
        nextEpisode = nil
      }
    } catch {
      Logger.episode.error("fetch next episode error: \(error)")
    }
  }

  func markNextWatched() {
    guard let episodeId = nextEpisode?.episodeId else {
      return
    }
    if updating {
      return
    }
    updating = true
    Task {
      do {
        try await Chii.shared.updateEpisodeCollection(
          subjectId: subjectId, episodeId: episodeId, type: .collect)
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        await loadNextEpisode()
      } catch {
        Notifier.shared.alert(error: error)
      }
      updating = false
    }
  }

  var body: some View {
    VStack(alignment: .leading) {
      HStack {
        ImageView(img: subject?.images.common, width: 90, height: 120, type: .subject)
        VStack(alignment: .leading) {
          Text(subject?.name ?? "")
            .font(.headline)
            .lineLimit(1)

          HStack {
            if collection?.priv ?? false {
              Image(systemName: "lock.fill").foregroundStyle(.accent)
            }
            if let platform = subject?.platform, !platform.isEmpty {
              BorderView(.secondary, padding: 2) {
                Text(platform)
                  .font(.caption)
                  .foregroundStyle(.secondary)
              }
            }
            Text(subject?.nameCn ?? "")
              .foregroundStyle(.secondary)
              .font(.subheadline)
              .lineLimit(1)
          }

          Spacer()

          switch collection?.subjectTypeEnum {
          case .anime, .real:
            HStack {
              Text("\(collection?.epStatus ?? 0) / \(subject?.eps ?? 0)")
                .foregroundStyle(.secondary)
              Spacer()
              if let episode = nextEpisode {
                if episode.airdate > Date() {
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
                    Button("EP.\(episode.sort.episodeDisplay) 看过", action: markNextWatched)
                  }
                }
              } else {
                Image(systemName: "square.grid.2x2.fill")
                  .foregroundStyle(.secondary)
              }
            }
          case .book:
            SubjectBookChaptersView(subjectId: subjectId, compact: true)

          default:
            Label(
              collection?.subjectTypeEnum.description ?? "",
              systemImage: collection?.subjectTypeEnum.icon ?? "questionmark"
            )
            .foregroundStyle(.accent)
          }

          Spacer()
          Text(collection?.updatedAt.formatRelative ?? "")
            .font(.footnote)
            .foregroundStyle(.secondary)
            .lineLimit(1)

        }
        .padding(.horizontal, 2)
      }

      switch collection?.subjectTypeEnum {
      case .book:
        ProgressView(value: Float(min(subject?.eps ?? 0, collection?.epStatus ?? 0)), total: Float(subject?.eps ?? 0))
          .progressViewStyle(.linear)
          .frame(height: 1)
        ProgressView(value: Float(min(subject?.volumes ?? 0, collection?.volStatus ?? 0)), total: Float(subject?.volumes ?? 0))
          .progressViewStyle(.linear)
          .frame(height: 1)

      case .anime, .real:
        ProgressView(value: Float(min(subject?.eps ?? 0, collection?.epStatus ?? 0)), total: Float(subject?.eps ?? 0))
          .progressViewStyle(.linear)
          .frame(height: 1)

      default:
        ProgressView(value: 0, total: 0)
          .progressViewStyle(.linear)
          .frame(height: 1)
      }

    }
    .task {
      await loadNextEpisode()
    }
  }
}

#Preview {
  let container = mockContainer()

  let collection = UserSubjectCollection.previewAnime
  let subject = Subject.previewAnime
  let episodes = Episode.previewList
  container.mainContext.insert(subject)
  container.mainContext.insert(collection)
  for episode in episodes {
    container.mainContext.insert(episode)
  }

  return ScrollView {
    LazyVStack(alignment: .leading) {
      ProgressRowView(subjectId: subject.subjectId)
    }
  }
  .padding()
  .modelContainer(container)
}
