//
//  EpisodeGridView.swift
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

  @State private var selected: Episode? = nil
  @State private var refreshed: Bool = false

  @Query
  private var episodeMains: [Episode]
  @Query
  private var episodeSps: [Episode]

  init(subjectId: UInt) {
    self.subjectId = subjectId

    let mainType = EpisodeType.main.rawValue
    var mainDescriptor = FetchDescriptor<Episode>(
      predicate: #Predicate<Episode> {
        $0.type == mainType && $0.subjectId == subjectId
      }, sortBy: [SortDescriptor(\.sort)])
    mainDescriptor.fetchLimit = 50
    _episodeMains = Query(mainDescriptor)

    let spType = EpisodeType.sp.rawValue
    var spDescriptor = FetchDescriptor<Episode>(
      predicate: #Predicate<Episode> {
        $0.type == spType && $0.subjectId == subjectId
      }, sortBy: [SortDescriptor(\.sort)])
    spDescriptor.fetchLimit = 10
    _episodeSps = Query(spDescriptor)
  }

  func refresh() async {
    if refreshed { return }
    refreshed = true

    do {
      try await chii.loadEpisodes(subjectId)
      try await chii.db.save()
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
    }.onAppear {
      Task(priority: .background) {
        await refresh()
      }
    }
    FlowStack {
      ForEach(episodeMains) { episode in
        Button {
          selected = episode
        } label: {
          Text("\(episode.sort.episodeDisplay)")
            .foregroundStyle(Color(hex: episode.textColor))
            .padding(3)
            .background(Color(hex: episode.backgroundColor))
            .border(Color(hex: episode.borderColor), width: 1)
            .padding(2)
            .monospaced()
            .strikethrough(episode.collection == EpisodeCollectionType.dropped.rawValue)
        }
      }
      if !episodeSps.isEmpty {
        Text("SP")
          .foregroundStyle(Color(hex: 0x8EB021))
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
        ForEach(episodeSps) { episode in
          Button {
            selected = episode
          } label: {
            Text("\(episode.sort.episodeDisplay)")
              .foregroundStyle(Color(hex: episode.textColor))
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
    .animation(.default, value: episodeMains)
    .animation(.default, value: episodeSps)
    .animation(.default, value: selected)
    .sheet(
      item: $selected,
      content: { episode in
        EpisodeInfoboxView(subjectId: subjectId, episodeId: episode.id)
          .presentationDragIndicator(.visible)
          .presentationDetents(.init([.medium, .large]))
      }
    )
  }
}

#Preview {
  let container = mockContainer()

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
        .environment(ChiiClient(container: container, mock: .anime))
        .modelContainer(container)
    }
  }.padding()
}
