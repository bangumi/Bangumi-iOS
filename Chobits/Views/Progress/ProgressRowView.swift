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
  let subjectId: Int

  @Environment(\.modelContext) var modelContext

  @State private var updating: Bool = false

  @Query private var subjects: [Subject]
  private var subject: Subject? { subjects.first }

  @Query private var collections: [UserSubjectCollection]
  private var collection: UserSubjectCollection? { collections.first }

  @Query private var pendingEpisodes: [Episode]
  private var nextEpisode: Episode? { pendingEpisodes.first }

  init(subjectId: Int) {
    self.subjectId = subjectId

    _subjects = Query(filter: #Predicate<Subject> { $0.subjectId == subjectId })
    _collections = Query(filter: #Predicate<UserSubjectCollection> { $0.subjectId == subjectId })

    var descriptor = FetchDescriptor<Episode>(
      predicate: #Predicate<Episode> {
        $0.subjectId == subjectId && $0.type == 0 && $0.collection == 0
      }, sortBy: [SortDescriptor<Episode>(\.sort, order: .forward)])
    descriptor.fetchLimit = 1
    _pendingEpisodes = Query(descriptor)
  }

  var totalEps: Int {
    subject?.eps ?? 0
  }

  var totalVols: Int {
    subject?.volumes ?? 0
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
      } catch {
        Notifier.shared.alert(error: error)
      }
      updating = false
    }
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 4) {
      HStack {
        NavigationLink(value: NavDestination.subject(subjectId)) {
          ImageView(
            img: subject?.images?.common,
            width: 72, height: 72, type: .subject
          ) {
            if collection?.priv ?? false {
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
          NavigationLink(value: NavDestination.subject(subjectId)) {
            VStack(alignment: .leading) {
              Text(subject?.name ?? "")
                .font(.headline)
                .lineLimit(1)
              Text(subject?.nameCN ?? "")
                .foregroundStyle(.secondary)
                .font(.subheadline)
                .lineLimit(1)
            }
          }.buttonStyle(.plain)

          Spacer()

          switch subject?.typeEnum {
          case .anime, .real:
            HStack {
              Text("\(collection?.epStatus ?? 0) / \(totalEps)")
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
                NavigationLink(value: NavDestination.subject(subjectId)) {
                  Image(systemName: "square.grid.2x2.fill")
                    .foregroundStyle(.secondary)
                }.buttonStyle(.plain)
              }
            }.font(.callout)
          case .book:
            SubjectBookChaptersView(subjectId: subjectId, compact: true)
              .font(.callout)

          default:
            if let stype = subject?.typeEnum {
              Label(stype.description, systemImage: stype.icon)
                .foregroundStyle(.accent)
                .font(.callout)
            }
          }
        }
      }

      Section {
        switch subject?.typeEnum {
        case .book:
          VStack(spacing: 1) {
            ProgressView(
              value: Float(min(totalEps, collection?.epStatus ?? 0)), total: Float(totalEps))
            ProgressView(
              value: Float(min(totalVols, collection?.volStatus ?? 0)), total: Float(totalVols))
          }.progressViewStyle(.linear)

        case .anime, .real:
          ProgressView(
            value: Float(min(totalEps, collection?.epStatus ?? 0)), total: Float(totalEps)
          )
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
  for episode in episodes {
    container.mainContext.insert(episode)
  }

  return ScrollView {
    LazyVStack(alignment: .leading) {
      ProgressRowView(subjectId: subject.subjectId)
        .modelContainer(container)
    }.padding()
  }
}
