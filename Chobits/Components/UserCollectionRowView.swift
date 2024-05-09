//
//  UserCollectionRowView.swift
//  Chobits
//
//  Created by Chuan Chuan on 2024/4/21.
//

import OSLog
import SwiftData
import SwiftUI

struct UserCollectionRowView: View {
  let subjectId: UInt

  @EnvironmentObject var notifier: Notifier
  @EnvironmentObject var chii: ChiiClient

  @State private var showEpisodeBox: Bool = false
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
        $0.id == subjectId
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
      let episode = try await chii.db.fetchOne(
        predicate: #Predicate<Episode> {
          $0.subjectId == subjectId && $0.type == zero && $0.collection == zero
        }, sortBy: [SortDescriptor<Episode>(\.sort, order: .forward)])
      if let episode = episode {
        Logger.episode.info("subject \(subjectId) next episode: \(episode.sort.episodeDisplay)")
      }
      nextEpisode = episode
    } catch {
      Logger.episode.error("fetch next episode error: \(error)")
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
    ZStack {
      Rectangle()
        .fill(.accent)
        .opacity(0.01)
        .frame(height: 64)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .shadow(color: .accent, radius: 1, x: 1, y: 1)
        .task {
          await loadNextEpisode()
        }
      HStack {
        ImageView(img: subject?.images.common, width: 60, height: 60)
        VStack(alignment: .leading) {
          Text(subject?.name ?? "").font(.headline)
          Text(subject?.nameCn ?? "").font(.footnote).foregroundStyle(.secondary)
          if let collection = collection {
            HStack(alignment: .bottom) {
              Text(collection.updatedAt.formatCollectionDate).foregroundStyle(.secondary)
              if collection.priv {
                Image(systemName: "lock.fill").foregroundStyle(.accent)
              }
              Spacer()
              switch collection.subjectTypeEnum {
              case .anime, .real:
                if let episode = nextEpisode {
                  if episode.airdate > Date() {
                    Text("EP.\(episode.sort.episodeDisplay) ~ \(episode.waitDays) days")
                      .foregroundStyle(.secondary)
                  } else {
                    Button {
                      showEpisodeBox = true
                    } label: {
                      Label("EP.\(episode.sort.episodeDisplay)", systemImage: "eyes").font(.callout)
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
        Spacer()
      }
      .frame(height: 60)
      .padding(2)
      .clipShape(RoundedRectangle(cornerRadius: 10))
      .sheet(
        isPresented: $showEpisodeBox,
        content: {
          if let episode = nextEpisode {
            EpisodeInfoboxView(subjectId: subjectId, episodeId: episode.id)
              .presentationDragIndicator(.visible)
              .presentationDetents(.init([.medium, .large]))
          }
        }
      )
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
      UserCollectionRowView(subjectId: subject.id)
        .environmentObject(Notifier())
        .environment(ChiiClient(container: container, mock: .anime))
    }
  }
  .padding()
  .modelContainer(container)
}
