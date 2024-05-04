//
//  Episodes.swift
//  Chobits
//
//  Created by Chuan Chuan on 2024/5/3.
//

import OSLog
import SwiftData
import SwiftUI

struct SubjectEpisodesView: View {
  let subject: Subject

  @EnvironmentObject var notifier: Notifier
  @EnvironmentObject var chii: ChiiClient
  @Environment(\.modelContext) private var modelContext

  @State private var selectedEpisode: Episode? = nil
  @State private var selectedCollection: EpisodeCollection? = nil
  @StateObject private var page: PageStatus = PageStatus()

  @Query private var episodes: [Episode]
  @Query private var collections: [EpisodeCollection]

  init(subject: Subject) {
    self.subject = subject
    _episodes = Query(
      filter: #Predicate<Episode> { episode in
        episode.subjectId == subject.id
      }, sort: \Episode.sort)
    _collections = Query(
      filter: #Predicate<EpisodeCollection> { collection in
        collection.subjectId == subject.id
      }, sort: \EpisodeCollection.sort)
  }

  func update() async {
    if !self.page.start() {
      return
    }
    let actor = BackgroundActor(container: modelContext.container)
    do {
      var offset: Int = 0
      let limit: Int = 50
      let subjectId = subject.id
      while true {
        var total: Int = 0
        if chii.isAuthenticated {
          let response = try await chii.getEpisodeCollections(
            subjectId: subject.id, type: nil, limit: limit, offset: offset)
          if response.data.isEmpty {
            break
          }
          for item in response.data {
            let collection = EpisodeCollection(item: item, subjectId: subjectId)
            await actor.insert(data: collection, background: true)
            let episode = Episode(item: item.episode, subjectId: subjectId)
            await actor.insert(data: episode, background: true)
          }
          total = response.total
        } else {
          let response = try await chii.getSubjectEpisodes(
            subjectId: subject.id, type: nil, limit: limit, offset: offset)
          if response.data.isEmpty {
            break
          }
          for episode in response.data {
            episode.subjectId = subjectId
            await actor.insert(data: episode, background: true)
          }
          total = response.total
        }
        offset += limit
        if offset > total {
          break
        }
      }
      try await actor.save()
      await MainActor.run {
        page.success()
      }
    } catch {
      print("ERR: \(error)")
      await MainActor.run {
        notifier.alert(error: error)
        page.finish()
      }
    }
  }

  var mainCollections: [EpisodeCollection] {
    return collections.filter { $0.episode.type.rawValue == EpisodeType.main.rawValue }.sorted(by: {
      $0.episode.sort < $1.episode.sort
    })
  }

  var body: some View {
    HStack {
      if chii.isAuthenticated {
        Text("观看进度管理:").font(.callout)
      } else {
        Text("章节列表:").font(.callout)
      }
    }.task {
      await update()
    }
    if chii.isAuthenticated {
      FlowStack {
        ForEach(mainCollections.prefix(50)) { collection in
          Button {
            selectedCollection = collection
          } label: {
            Text("\(collection.episode.sort.episodeDisplay)")
              .foregroundStyle(collection.textColor)
              .font(.callout)
              .padding(3)
              .background(collection.backgroundColor)
              .border(collection.borderColor, width: 1)
              .padding(2)
              .monospaced()
              .strikethrough(collection.type == EpisodeCollectionType.dropped.rawValue)
          }
        }
        ForEach(EpisodeType.otherTypes()) { type in
          let others = collections.filter { $0.episode.type.rawValue == type.rawValue }.sorted(by: {
            $0.episode.sort < $1.episode.sort
          }).prefix(10)
          if !others.isEmpty {
            Text(type.description)
              .foregroundStyle(Color(hex: 0x8EB021))
              .font(.callout)
              .padding(.vertical, 3)
              .padding(.leading, 5)
              .padding(.trailing, 1)
              .overlay(
                Rectangle()
                  .frame(width: 3)
                  .foregroundColor(Color(hex: 0x8EB021))
                  .offset(x: -12, y: 0)
              )
              .padding(2)
              .bold()
              .monospaced()
            ForEach(others) { collection in
              Button {
                selectedCollection = collection
              } label: {
                Text("\(collection.episode.sort.episodeDisplay)")
                  .foregroundStyle(collection.textColor)
                  .font(.callout)
                  .padding(3)
                  .background(collection.backgroundColor)
                  .border(collection.borderColor, width: 1)
                  .padding(2)
                  .monospaced()
                  .strikethrough(collection.type == EpisodeCollectionType.dropped.rawValue)
              }
            }
          }
        }
      }
      .animation(.default, value: collections)
      .sheet(
        item: $selectedCollection,
        content: { collection in
          EpisodeInfobox(collection: collection)
            .presentationDragIndicator(.visible)
            .presentationDetents(.init([.medium, .large]))
        }
      )
    } else {
      FlowStack {
        ForEach(episodes.prefix(50)) { episode in
          Button {
            selectedEpisode = episode
          } label: {
            Text("\(episode.sort.episodeDisplay)")
              .foregroundStyle(episode.textColor)
              .font(.callout)
              .padding(3)
              .background(episode.backgroundColor)
              .border(episode.borderColor, width: 1)
              .padding(2)
              .monospaced()
          }
        }
      }
      .animation(.default, value: episodes)
      .sheet(
        item: $selectedEpisode,
        content: { episode in
          EpisodeInfobox(episode: episode)
            .presentationDragIndicator(.visible)
            .presentationDetents(.init([.medium, .large]))
        })
    }
  }
}

#Preview {
  let config = ModelConfiguration(isStoredInMemoryOnly: true)
  let container = try! ModelContainer(
    for: UserSubjectCollection.self, Subject.self, Episode.self, EpisodeCollection.self,
    configurations: config)
  container.mainContext.insert(UserSubjectCollection.previewBook)

  return ScrollView {
    LazyVStack(alignment: .leading) {
      SubjectEpisodesView(subject: .previewAnime)
        .environmentObject(Notifier())
        .environmentObject(ChiiClient(mock: .anime))
    }
  }
  .padding()
  .modelContainer(container)
}
