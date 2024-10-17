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

  @Environment(Notifier.self) private var notifier
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
        UIImpactFeedbackGenerator(style: .soft).impactOccurred()
        await loadNextEpisode()
      } catch {
        notifier.alert(error: error)
      }
      updating = false
    }
  }

  var epsColor: Color {
    guard let collection = collection else { return .secondary }
    return collection.epStatus == 0 ? .secondary : .accent
  }

  var volsColor: Color {
    guard let collection = collection else { return .secondary }
    return collection.volStatus == 0 ? .secondary : .accent
  }

  var chapters: String {
    guard let subject = subject else { return "" }
    if subject.eps > 0 {
      return "/ \(subject.eps) 话"
    } else {
      return "/ ? 话"
    }
  }

  var volumes: String {
    guard let subject = subject else { return "" }
    if subject.volumes > 0 {
      return "/ \(subject.volumes) 卷"
    } else {
      return "/ ? 卷"
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
              Text(platform)
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 1)
                .overlay {
                  RoundedRectangle(cornerRadius: 5)
                    .stroke(.secondary, lineWidth: 1)
                    .padding(.horizontal, -1)
                    .padding(.vertical, -1)
                }
            }
            Text(subject?.nameCn ?? "")
              .foregroundStyle(.secondary)
              .font(.subheadline)
              .lineLimit(1)
          }

          if let authority = subject?.authority {
            Spacer()
            Text(authority)
              .font(.caption)
              .foregroundStyle(.secondary)
              .lineLimit(2)
          }

          Spacer()
          if let collection = collection {
            HStack(alignment: .bottom) {
              Text(collection.updatedAt.formatRelative)
                .foregroundStyle(.secondary)
                .lineLimit(1)
              Spacer()
              switch collection.subjectTypeEnum {
              case .anime, .real:
                if let episode = nextEpisode {
                  if episode.airdate > Date() {
                    Text("EP.\(episode.sort.episodeDisplay) ~ \(episode.waitDesc)")
                      .foregroundStyle(.secondary)
                  } else {
                    if updating {
                      ZStack {
                        Button("EP...", action: {})
                          .font(.callout)
                          .disabled(true)
                          .hidden()
                        ProgressView()
                      }
                    } else {
                      Button("EP.\(episode.sort.episodeDisplay)", action: markNextWatched)
                        .font(.callout)
                    }
                  }
                } else {
                  Text("\(collection.epStatus)").foregroundStyle(epsColor).font(.callout)
                  Text(chapters).foregroundStyle(epsColor)
                }
              case .book:
                Text("\(collection.epStatus)").foregroundStyle(epsColor).font(.callout)
                Text("\(chapters)").foregroundStyle(epsColor)
                Text("\(collection.volStatus)").foregroundStyle(volsColor).font(.callout)
                Text("\(volumes)").foregroundStyle(volsColor)
              default:
                Label(
                  collection.subjectTypeEnum.description,
                  systemImage: collection.subjectTypeEnum.icon
                )
                .foregroundStyle(.accent)
              }
            }.font(.footnote)
          }
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
        .environment(Notifier())
    }
  }
  .padding()
  .modelContainer(container)
}
