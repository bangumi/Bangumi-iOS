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
        ImageView(img: subject?.images.common, width: 72, height: 96, type: .subject)
        VStack(alignment: .leading) {
          Text(subject?.name ?? "")
            .font(.headline)
            .lineLimit(1)
          Text(subject?.nameCn ?? "")
            .foregroundStyle(.secondary)
            .font(.subheadline)
            .lineLimit(1)

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
            }.font(.callout)
          case .book:
            SubjectBookChaptersView(subjectId: subjectId, compact: true)
              .font(.callout)

          default:
            if let stype = collection?.subjectTypeEnum {
              Label(stype.description, systemImage: stype.icon)
              .foregroundStyle(.accent)
              .font(.callout)
            }
          }

          Spacer()
          HStack {
            Text(collection?.updatedAt.formatRelative ?? "")
              .lineLimit(1)
            Spacer()
            if collection?.priv ?? false {
              Image(systemName: "lock.fill")
            }
          }
          .font(.footnote)
          .foregroundStyle(.secondary)
        }
      }

      Section {
        switch collection?.subjectTypeEnum {
        case .book:
          VStack(spacing: 1) {
            ProgressView(value: Float(min(subject?.eps ?? 0, collection?.epStatus ?? 0)), total: Float(subject?.eps ?? 0))
            ProgressView(value: Float(min(subject?.volumes ?? 0, collection?.volStatus ?? 0)), total: Float(subject?.volumes ?? 0))
          }.progressViewStyle(.linear)

        case .anime, .real:
          ProgressView(value: Float(min(subject?.eps ?? 0, collection?.epStatus ?? 0)), total: Float(subject?.eps ?? 0))
            .progressViewStyle(.linear)

        default:
          ProgressView(value: 0, total: 0)
            .progressViewStyle(.linear)
        }
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
