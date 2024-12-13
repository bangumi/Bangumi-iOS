//
//  EpisodeGridView.swift
//  Chobits
//
//  Created by Chuan Chuan on 2024/5/5.
//

import Flow
import OSLog
import SwiftData
import SwiftUI

struct EpisodeGridView: View {
  let subjectId: Int

  @AppStorage("isolationMode") var isolationMode: Bool = false
  @AppStorage("isAuthenticated") var isAuthenticated: Bool = false

  @Environment(\.modelContext) var modelContext

  @State private var refreshed: Bool = false

  @Query private var subjects: [Subject]
  private var subject: Subject? { subjects.first }

  @Query private var episodeMains: [Episode] = []
  @Query private var episodeSps: [Episode] = []

  init(subjectId: Int) {
    self.subjectId = subjectId

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

    _episodeMains = Query(mainDescriptor)
    _episodeSps = Query(spDescriptor)
    _subjects = Query(filter: #Predicate<Subject> { $0.subjectId == subjectId })
  }

  func refresh() {
    if refreshed { return }
    refreshed = true

    Task {
      do {
        try await Chii.shared.loadEpisodes(subjectId)
      } catch {
        Notifier.shared.alert(error: error)
      }
    }
  }

  func updateSingle(episode: Episode, type: EpisodeCollectionType) {
    Task {
      do {
        try await Chii.shared.updateEpisodeCollection(
          subjectId: episode.subjectId, episodeId: episode.episodeId, type: type)
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
      } catch {
        Notifier.shared.alert(error: error)
      }
    }
  }

  func updateBatch(episode: Episode) {
    Task {
      do {
        try await Chii.shared.updateSubjectEpisodeCollection(
          subjectId: subjectId, updateTo: episode.sort, type: .collect)
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
      } catch {
        Notifier.shared.alert(error: error)
      }
    }
  }

  var body: some View {
    VStack(spacing: 2) {
      HStack(alignment: .bottom) {
        if isAuthenticated {
          Text("观看进度管理:")
        } else {
          Text("章节列表:")
        }
        Spacer()
        NavigationLink(value: NavDestination.episodeList(subjectId: subjectId)) {
          Text("全部章节 »").font(.caption).foregroundStyle(.linkText)
        }.buttonStyle(.plain)
      }.onAppear(perform: refresh)
      Divider()
    }.padding(.top, 5)
    HFlow(alignment: .center, spacing: 2) {
      ForEach(episodeMains) { episode in
        Text("\(episode.sort.episodeDisplay)")
          .foregroundStyle(Color(hex: episode.textColor))
          .padding(3)
          .background(Color(hex: episode.backgroundColor))
          .border(Color(hex: episode.borderColor), width: 1)
          .padding(2)
          .strikethrough(episode.collection == EpisodeCollectionType.dropped.rawValue)
          .contextMenu {
            if isAuthenticated, subject?.userCollection != nil {
              ForEach(episode.collectionTypeEnum.otherTypes()) { type in
                Button {
                  updateSingle(episode: episode, type: type)
                } label: {
                  Label(type.action, systemImage: type.icon)
                }
              }
              Button {
                updateBatch(episode: episode)
              } label: {
                Label("看到", systemImage: "checklist.checked")
              }
            }
            NavigationLink(
              value: NavDestination.episode(
                subjectId: episode.subjectId, episodeId: episode.episodeId)
            ) {
              Label("查看讨论...", systemImage: "bubble")
            }
          } preview: {
            EpisodeInfoView(episode: episode)
              .padding()
              .frame(idealWidth: 320)
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
          Text("\(episode.sort.episodeDisplay)")
            .foregroundStyle(Color(hex: episode.textColor))
            .padding(3)
            .background(Color(hex: episode.backgroundColor))
            .border(Color(hex: episode.borderColor), width: 1)
            .padding(2)
            .strikethrough(episode.collection == EpisodeCollectionType.dropped.rawValue)
            .contextMenu {
              if isAuthenticated, subject?.userCollection != nil {
                ForEach(episode.collectionTypeEnum.otherTypes()) { type in
                  Button {
                    updateSingle(episode: episode, type: type)
                  } label: {
                    Label(type.action, systemImage: type.icon)
                  }
                }
              }
              NavigationLink(
                value: NavDestination.episode(
                  subjectId: episode.subjectId, episodeId: episode.episodeId)
              ) {
                Label("查看讨论...", systemImage: "bubble")
              }
            } preview: {
              EpisodeInfoView(episode: episode)
                .padding()
                .frame(idealWidth: 320)
            }
        }
      }
    }
    .animation(.default, value: episodeMains)
    .animation(.default, value: episodeSps)
  }
}

#Preview {
  let container = mockContainer()

  container.mainContext.insert(UserSubjectCollection.previewAnime)

  let subject = Subject.previewAnime
  container.mainContext.insert(subject)

  let episodes = Episode.previewAnime
  for episode in episodes {
    container.mainContext.insert(episode)
  }

  return ScrollView {
    LazyVStack(alignment: .leading) {
      EpisodeGridView(subjectId: subject.subjectId)
        .modelContainer(container)
    }
  }.padding()
}
