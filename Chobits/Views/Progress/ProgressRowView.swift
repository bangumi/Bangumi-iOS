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
  @ObservableModel var collection: UserSubjectCollection

  @Environment(\.modelContext) var modelContext

  @State private var updating: Bool = false

  @Query private var pendingEpisodes: [Episode]
  private var nextEpisode: Episode? { pendingEpisodes.first }

  init(collection: UserSubjectCollection) {
    _collection = ObservableModel(wrappedValue: collection)

    let subjectId = collection.subjectId
    var descriptor = FetchDescriptor<Episode>(
      predicate: #Predicate<Episode> {
        $0.subjectId == subjectId && $0.type == 0 && $0.collection == 0
      }, sortBy: [SortDescriptor<Episode>(\.sort, order: .forward)])
    descriptor.fetchLimit = 1
    _pendingEpisodes = Query(descriptor)
  }

  var totalEps: Int {
    collection.subject?.eps ?? 0
  }

  var totalVols: Int {
    collection.subject?.volumes ?? 0
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
          subjectId: collection.subjectId, episodeId: episodeId, type: .collect)
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
      } catch {
        Notifier.shared.alert(error: error)
      }
      updating = false
    }
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 4) {
      HStack {
        NavigationLink(value: NavDestination.subject(collection.subjectId)) {
          ImageView(
            img: collection.subject?.images?.common,
            width: 72, height: 72, type: .subject
          ) {
            if collection.priv {
              Image(systemName: "lock")
                .padding(2)
                .background(.red.opacity(0.8))
                .padding(2)
                .foregroundStyle(.white)
                .font(.caption)
                .clipShape(Capsule())
            }
          }
        }.buttonStyle(.navLink)
        VStack(alignment: .leading) {
          NavigationLink(value: NavDestination.subject(collection.subjectId)) {
            VStack(alignment: .leading) {
              Text(collection.subject?.name ?? "")
                .font(.headline)
                .lineLimit(1)
              Text(collection.subject?.nameCN ?? "")
                .foregroundStyle(.secondary)
                .font(.subheadline)
                .lineLimit(1)
            }
          }.buttonStyle(.plain)

          Spacer()

          switch collection.subject?.typeEnum {
          case .anime, .real:
            HStack {
              Text("\(collection.epStatus) / \(totalEps)")
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
                    Button("EP.\(episode.sort.episodeDisplay) 看过", action: markNextWatched)
                  }
                }
              } else {
                NavigationLink(value: NavDestination.subject(collection.subjectId)) {
                  Image(systemName: "square.grid.2x2.fill")
                    .foregroundStyle(.secondary)
                }.buttonStyle(.plain)
              }
            }.font(.callout)
          case .book:
            SubjectBookChaptersView(subjectId: collection.subjectId, compact: true)
              .font(.callout)

          default:
            if let stype = collection.subject?.typeEnum {
              Label(stype.description, systemImage: stype.icon)
                .foregroundStyle(.accent)
                .font(.callout)
            }
          }
        }
      }

      Section {
        switch collection.subject?.typeEnum {
        case .book:
          VStack(spacing: 1) {
            ProgressView(value: Float(min(totalEps, collection.epStatus)), total: Float(totalEps))
            ProgressView(
              value: Float(min(totalVols, collection.volStatus)), total: Float(totalVols))
          }.progressViewStyle(.linear)

        case .anime, .real:
          ProgressView(value: Float(min(totalEps, collection.epStatus)), total: Float(totalEps))
            .progressViewStyle(.linear)

        default:
          ProgressView(value: 0, total: 0)
            .progressViewStyle(.linear)
        }
      }
    }
  }
}

#Preview {
  let container = mockContainer()

  let collection = UserSubjectCollection.previewAnime
  let subject = Subject.previewAnime
  let episodes = Episode.previewCollections
  container.mainContext.insert(subject)
  container.mainContext.insert(collection)
  collection.subject = subject
  for episode in episodes {
    container.mainContext.insert(episode)
  }

  return ScrollView {
    LazyVStack(alignment: .leading) {
      ProgressRowView(collection: collection)
    }
  }
  .padding()
  .modelContainer(container)
}
