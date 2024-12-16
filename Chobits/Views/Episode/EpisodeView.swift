//
//  EpisodeView.swift
//  Chobits
//
//  Created by Chuan Chuan on 2024/5/4.
//

import SwiftData
import SwiftUI

struct EpisodeView: View {
  let subjectId: Int
  let episodeId: Int

  @AppStorage("shareDomain") var shareDomain: String = ShareDomain.chii.label
  @AppStorage("isolationMode") var isolationMode: Bool = false
  @AppStorage("isAuthenticated") var isAuthenticated: Bool = false

  @Environment(\.dismiss) private var dismiss

  @State private var updating: Bool = false

  @Query private var subjects: [Subject]
  private var subject: Subject? { subjects.first }

  @Query private var episodes: [Episode]
  private var episode: Episode? { episodes.first }

  @Query private var collections: [UserSubjectCollection]
  private var collection: UserSubjectCollection? { collections.first }

  init(subjectId: Int, episodeId: Int) {
    self.subjectId = subjectId
    self.episodeId = episodeId

    _subjects = Query(filter: #Predicate<Subject> { $0.subjectId == subjectId })
    _episodes = Query(filter: #Predicate<Episode> { $0.episodeId == episodeId })
    _collections = Query(filter: #Predicate<UserSubjectCollection> { $0.subjectId == subjectId })
  }

  var showCollectionBox: Bool {
    if !isAuthenticated { return false }
    if collection == nil { return false }
    switch subject?.typeEnum {
    case .anime, .real:
      return true
    default:
      return false
    }
  }

  var shareLink: URL {
    URL(string: "https://\(shareDomain)/ep/\(episodeId)")!
  }

  func updateSingle(type: EpisodeCollectionType) {
    if updating { return }
    updating = true
    Task {
      do {
        try await Chii.shared.updateEpisodeCollection(
          subjectId: subjectId, episodeId: episodeId, type: type)
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        updating = false
        dismiss()
      } catch {
        updating = false
        Notifier.shared.alert(error: error)
      }
    }
  }

  func updateBatch() {
    if updating { return }
    guard let episode = episode else {
      Notifier.shared.alert(message: "Episode not found")
      return
    }
    updating = true
    Task {
      do {
        try await Chii.shared.updateSubjectEpisodeCollection(
          subjectId: subjectId, updateTo: episode.sort, type: .collect)
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        updating = false
        dismiss()
      } catch {
        updating = false
        Notifier.shared.alert(error: error)
      }
    }
  }

  var body: some View {
    ScrollView {
      LazyVStack(alignment: .leading) {
        if let episode = episode {
          EpisodeInfoView(episode: episode)
        }
        if showCollectionBox {
          HStack {
            ForEach(episode?.collectionTypeEnum.otherTypes() ?? []) { type in
              Button {
                updateSingle(type: type)
              } label: {
                Text(type.action)
              }
            }.buttonStyle(.borderedProminent)
            Button {
              updateBatch()
            } label: {
              Text("看到")
            }
            .buttonStyle(.bordered)
            .foregroundStyle(.accent)
            Spacer()
            Text(episode?.collectionTypeEnum.description ?? "")
              .font(.footnote)
              .foregroundStyle(.accent)
          }
          .disabled(updating)
        }
        Divider()
        if let desc = episode?.desc, !desc.isEmpty {
          Text(desc).foregroundStyle(.secondary)
        }
        Spacer()
      }.padding(.horizontal, 8)
    }
    .navigationTitle("章节详情")
    .navigationBarTitleDisplayMode(.inline)
    .toolbar {
      ToolbarItem(placement: .topBarTrailing) {
        Menu {
          ShareLink(item: shareLink) {
            Label("分享", systemImage: "square.and.arrow.up")
          }
        } label: {
          Image(systemName: "ellipsis.circle")
        }
      }
    }
  }
}

#Preview {
  let container = mockContainer()

  container.mainContext.insert(UserSubjectCollection.previewAnime)
  let subject = Subject.previewAnime
  container.mainContext.insert(subject)

  let episodes = Episode.previewCollections
  for episode in episodes {
    container.mainContext.insert(episode)
  }

  return EpisodeView(
    subjectId: subject.subjectId, episodeId: episodes.first!.episodeId
  )
  .modelContainer(container)
}
