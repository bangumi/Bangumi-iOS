//
//  EpisodeCollection.swift
//  Chobits
//
//  Created by Chuan Chuan on 2024/5/5.
//

import OSLog
import SwiftData
import SwiftUI

struct EpisodeGridView: View {
  let subjectId: UInt

  @EnvironmentObject var notifier: Notifier
  @EnvironmentObject var chii: ChiiClient
  @Environment(\.modelContext) private var modelContext

  @State private var refreshed: Bool = false
  @State private var selected: Episode? = nil
  @State private var episodes: [EpisodeType: [Episode]] = [:]

  func fetch() async {
    let actor = BackgroundActor(container: modelContext.container)
    do {
      for type in EpisodeType.allTypes() {
        let typeValue = type.rawValue
        var descripter = FetchDescriptor<Episode>(
          predicate: #Predicate<Episode> {
            $0.subjectId == subjectId && $0.type == typeValue
          }, sortBy: [SortDescriptor(\.sort)])
        if type == .main {
          descripter.fetchLimit = 50
        } else {
          descripter.fetchLimit = 10
        }
        let eps = try await actor.fetchData(descriptor: descripter)
        episodes[type] = eps
      }
    } catch {
      notifier.alert(error: error)
    }
  }

  func update(authenticated: Bool) async {
    if refreshed { return }
    let actor = BackgroundActor(container: modelContext.container)
    do {
      var offset: Int = 0
      let limit: Int = 1000
      while true {
        var total: Int = 0
        if authenticated {
          let response = try await chii.getEpisodeCollections(
            subjectId: subjectId, type: nil, limit: limit, offset: offset)
          if response.data.isEmpty {
            break
          }
          for item in response.data {
            let episode = Episode(collection: item, subjectId: subjectId)
            await actor.insert(data: episode)
          }
          total = response.total
        } else {
          let response = try await chii.getSubjectEpisodes(
            subjectId: subjectId, type: nil, limit: limit, offset: offset)
          if response.data.isEmpty {
            break
          }
          for item in response.data {
            let episode = Episode(item: item, subjectId: subjectId)
            await actor.insert(data: episode)
          }
          total = response.total
        }
        offset += limit
        if offset > total {
          break
        }
      }
      try await actor.save()
      refreshed = true
    } catch {
      notifier.alert(error: error)
    }
  }

  var body: some View {
    HStack {
      if chii.isAuthenticated {
        Text("观看进度管理:")
      } else {
        Text("章节列表:")
      }
      NavigationLink(value: NavDestination.episodeList(subjectId: subjectId)) {
        Text("[全部]").foregroundStyle(Color("LinkTextColor"))
      }.buttonStyle(.plain)
      Spacer()
    }
    .font(.callout)
    .onAppear {
      Task(priority: .background) {
        await update(authenticated: chii.isAuthenticated)
        await fetch()
      }
    }
    if episodes.isEmpty {
      ProgressView().task {
        await fetch()
      }
    }
    FlowStack {
      ForEach(episodes[.main, default: []]) { episode in
        Button {
          selected = episode
        } label: {
          Text("\(episode.sort.episodeDisplay)")
            .foregroundStyle(Color(hex: episode.textColor))
            .font(.callout)
            .padding(3)
            .background(Color(hex: episode.backgroundColor))
            .border(Color(hex: episode.borderColor), width: 1)
            .padding(2)
            .monospaced()
            .strikethrough(episode.collection == EpisodeCollectionType.dropped.rawValue)
        }
      }
      ForEach(EpisodeType.otherTypes()) { type in
        if !episodes[type, default: []].isEmpty {
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
          ForEach(episodes[type, default: []]) { episode in
            Button {
              selected = episode
            } label: {
              Text("\(episode.sort.episodeDisplay)")
                .foregroundStyle(Color(hex: episode.textColor))
                .font(.callout)
                .padding(3)
                .background(Color(hex: episode.backgroundColor))
                .border(Color(hex: episode.borderColor), width: 1)
                .padding(2)
                .monospaced()
                .strikethrough(episode.collection == EpisodeCollectionType.dropped.rawValue)
            }
          }
        }
      }
    }
    .animation(.default, value: episodes)
    .animation(.default, value: selected)
    .sheet(
      item: $selected,
      content: { episode in
        EpisodeInfobox(subjectId: subjectId, episodeId: episode.id)
          .presentationDragIndicator(.visible)
          .presentationDetents(.init([.medium, .large]))
      }
    )
  }
}

#Preview {
  let config = ModelConfiguration(isStoredInMemoryOnly: true)
  let container = try! ModelContainer(
    for: UserSubjectCollection.self, Subject.self, Episode.self,
    configurations: config)
  container.mainContext.insert(UserSubjectCollection.previewAnime)

  let subject = Subject.previewAnime
  container.mainContext.insert(subject)

  let episodes = Episode.previewList
  for episode in episodes {
    container.mainContext.insert(episode)
  }

  return ScrollView {
    LazyVStack(alignment: .leading) {
      EpisodeGridView(subjectId: subject.id)
        .environmentObject(Notifier())
        .environmentObject(ChiiClient(mock: .anime))
        .modelContainer(container)
    }
  }.padding()
}
