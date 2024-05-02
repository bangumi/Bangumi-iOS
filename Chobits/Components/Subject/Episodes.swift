//
//  Episodes.swift
//  Chobits
//
//  Created by Chuan Chuan on 2024/5/3.
//

import SwiftData
import SwiftUI

struct SubjectEpisodesView: View {
  var subject: Subject

  @EnvironmentObject var notifier: Notifier
  @EnvironmentObject var chii: ChiiClient
  @Environment(\.modelContext) private var modelContext

  @Query private var episodes: [Episode]
  @Query private var collections: [EpisodeCollection]

  @StateObject private var page: PageStatus = PageStatus()
  @State private var edit: Bool = false

  init(subject: Subject) {
    self.subject = subject
    _episodes = Query(
      filter: #Predicate<Episode> { episode in
        episode.subjectId == subject.id
      })
    _collections = Query(
      filter: #Predicate<EpisodeCollection> { collection in
        collection.subjectId == subject.id
      })
  }

  func update() {
    if !self.page.start() {
      return
    }
    let actor = BackgroundActor(container: modelContext.container)
    Task {
      do {
        var offset: UInt = 0
        let limit: UInt = 50
        let subjectId = subject.id
        while true {
          print("fetch collection at offset: \(offset)")
          var total: UInt = 0
          if chii.isAuthenticated {
            let response = try await chii.getEpisodeCollections(
              subjectId: subject.id, type: nil, limit: limit, offset: offset)
            if response.data.isEmpty {
              break
            }
            print("got \(response.data.count) episodes")
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
            print("got \(response.data.count) episodes")
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
        await MainActor.run {
          page.success()
        }
      } catch {
        print("ERR: \(error)")
        await MainActor.run {
          notifier.alert(message: "\(error)")
          page.finish()
        }
      }
    }
  }

  var mainCollections: [EpisodeCollection] {
    let displayLimit = 50
    let mains = collections.filter { $0.episode.type == .main }.sorted(by: {
      $0.episode.sort < $1.episode.sort
    })
    if mains.count < displayLimit {
      return mains
    }
    var todoIdx = 0
    for (idx, collect) in mains.enumerated() {
      switch collect.type {
      case .none:
        todoIdx = idx == 0 ? 0 : idx - 1
        break
      default:
        continue
      }
    }
    return Array(mains[todoIdx..<min(todoIdx + displayLimit, mains.count)])
  }

  var body: some View {
    HStack {
      if chii.isAuthenticated {
        Text("观看进度管理:").font(.callout)
      } else {
        Text("章节列表:").font(.callout)
      }
    }.onAppear(perform: update)
    if chii.isAuthenticated {
      FlowStack {
        ForEach(mainCollections) { collection in
          Button {
            edit = true
          } label: {
            Text("\(collection.episode.sort.episodeDisplay)")
              .foregroundStyle(collection.textColor)
              .font(.callout)
              .padding(3)
              .background(collection.backgroundColor)
              .border(collection.borderColor, width: 1)
              .padding(2)
              .monospaced()
              .strikethrough(collection.type == .dropped)
          }
        }
        ForEach(EpisodeType.otherTypes()) { type in
          let others = collections.filter { $0.episode.type == type }.sorted(by: {
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
                edit = true
              } label: {
                Text("\(collection.episode.sort.episodeDisplay)")
                  .foregroundStyle(collection.textColor)
                  .font(.callout)
                  .padding(3)
                  .background(collection.backgroundColor)
                  .border(collection.borderColor, width: 1)
                  .padding(2)
                  .monospaced()
                  .strikethrough(collection.type == .dropped)
              }
            }
          }
        }
      }
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
