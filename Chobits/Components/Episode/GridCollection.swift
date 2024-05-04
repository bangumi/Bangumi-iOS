//
//  EpisodeCollection.swift
//  Chobits
//
//  Created by Chuan Chuan on 2024/5/5.
//

import OSLog
import SwiftData
import SwiftUI

struct EpisodeGridCollectionView: View {
  let subject: Subject

  @EnvironmentObject var notifier: Notifier
  @EnvironmentObject var chii: ChiiClient
  @Environment(\.modelContext) private var modelContext

  @State private var selectedCollection: EpisodeCollection? = nil
  @StateObject private var page: PageStatus = PageStatus()

  @Query private var collections: [EpisodeCollection]

  init(subject: Subject) {
    self.subject = subject

    var collectionDescriptor = FetchDescriptor<EpisodeCollection>(
      predicate: #Predicate<EpisodeCollection> {
        $0.subjectId == subject.id
      }, sortBy: [SortDescriptor(\.sort)])
    collectionDescriptor.fetchLimit = 50
    _collections = Query(collectionDescriptor)
  }

  func update() async {
    if !self.page.start() {
      return
    }
    let actor = BackgroundActor(container: modelContext.container)
    do {
      var offset: Int = 0
      let limit: Int = 1000
      let subjectId = subject.id
      while true {
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
        offset += limit
        if offset > response.total {
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
      Text("观看进度管理:")
      Spacer()
      NavigationLink(value: subject) {
        Text("[全部]").foregroundStyle(Color("LinkTextColor"))
      }.buttonStyle(.plain)
    }
    .font(.callout)
    .navigationDestination(for: Subject.self) { subject in
      EpisodeListCollectionView(subject: subject)
    }
    .task {
      await update()
    }
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
  }
}

#Preview {
  let config = ModelConfiguration(isStoredInMemoryOnly: true)
  let container = try! ModelContainer(
    for: UserSubjectCollection.self, Subject.self, Episode.self, EpisodeCollection.self,
    configurations: config)
  container.mainContext.insert(UserSubjectCollection.previewAnime)

  return ScrollView {
    LazyVStack(alignment: .leading) {
      EpisodeGridCollectionView(subject: .previewAnime)
        .environmentObject(Notifier())
        .environmentObject(ChiiClient(mock: .anime))
    }
  }
  .padding()
  .modelContainer(container)
}
