//
//  Grid.swift
//  Chobits
//
//  Created by Chuan Chuan on 2024/5/3.
//

import OSLog
import SwiftData
import SwiftUI

struct EpisodeGridView: View {
  let subject: Subject

  @EnvironmentObject var notifier: Notifier
  @EnvironmentObject var chii: ChiiClient
  @Environment(\.modelContext) private var modelContext

  @State private var selectedEpisode: Episode? = nil
  @StateObject private var page: PageStatus = PageStatus()

  @Query private var episodes: [Episode]

  init(subject: Subject) {
    self.subject = subject
    var episodeDescriptor = FetchDescriptor<Episode>(
      predicate: #Predicate<Episode> {
        $0.subjectId == subject.id
      }, sortBy: [SortDescriptor(\.sort)])
    episodeDescriptor.fetchLimit = 50
    _episodes = Query(episodeDescriptor)
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
        let response = try await chii.getSubjectEpisodes(
          subjectId: subject.id, type: nil, limit: limit, offset: offset)
        if response.data.isEmpty {
          break
        }
        for episode in response.data {
          episode.subjectId = subjectId
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

  var body: some View {
    HStack {
      Text("章节列表:")
      Spacer()
      NavigationLink(value: subject) {
        Text("[全部]").foregroundStyle(Color("LinkTextColor"))
      }.buttonStyle(.plain)
    }
    .font(.callout)
    .navigationDestination(for: Subject.self) { subject in
      EpisodeListView(subject: subject)
    }
    .task {
      await update()
    }
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
