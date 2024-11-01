//
//  EpisodeGridView.swift
//  Chobits
//
//  Created by Chuan Chuan on 2024/5/5.
//

import OSLog
import SwiftData
import SwiftUI
import Flow

struct EpisodeGridView: View {
  let subjectId: UInt

  @AppStorage("isAuthenticated") var isAuthenticated: Bool = false

  @Environment(Notifier.self) private var notifier
  @Environment(\.modelContext) var modelContext

  @State private var selected: Episode? = nil
  @State private var refreshed: Bool = false

  @State private var episodeMains: [Episode] = []
  @State private var episodeSps: [Episode] = []

  init(subjectId: UInt) {
    self.subjectId = subjectId
  }

  func load() async {
    let mainType = EpisodeType.main.rawValue
    var mainDescriptor = FetchDescriptor<Episode>(
      predicate: #Predicate<Episode> {
        $0.type == mainType && $0.subjectId == subjectId
      }, sortBy: [SortDescriptor(\.sort)])
    mainDescriptor.fetchLimit = 50

    let spType = EpisodeType.sp.rawValue
    var spDescriptor = FetchDescriptor<Episode>(
      predicate: #Predicate<Episode> {
        $0.type == spType && $0.subjectId == subjectId
      }, sortBy: [SortDescriptor(\.sort)])
    spDescriptor.fetchLimit = 10
    do {
      self.episodeMains = try modelContext.fetch(mainDescriptor)
      self.episodeSps = try modelContext.fetch(spDescriptor)
    } catch {
      notifier.alert(error: error)
    }
  }

  func refresh() async {
    if refreshed { return }
    refreshed = true

    do {
      try await Chii.shared.loadEpisodes(subjectId)
    } catch {
      notifier.alert(error: error)
    }
    await load()
  }

  var body: some View {
    HStack {
      if isAuthenticated {
        Text("观看进度管理:")
      } else {
        Text("章节列表:")
      }
      Spacer()
      NavigationLink(value: NavDestination.episodeList(subjectId: subjectId)) {
        Text("全部章节 »").font(.caption).foregroundStyle(.linkText)
      }.buttonStyle(.plain)
    }.onAppear {
      Task {
        await load()
        await refresh()
      }
    }
    HFlow(alignment: .center, spacing: 2) {
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
              .foregroundStyle(Color(hex: 0x8EB021))
              .offset(x: -12, y: 0)
          )
          .padding(2)
          .bold()
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
        EpisodeCollectionBoxView(subjectId: subjectId, episodeId: episode.episodeId)
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
      EpisodeGridView(subjectId: subject.subjectId)
        .environment(Notifier())
        .modelContainer(container)
    }
  }.padding()
}
