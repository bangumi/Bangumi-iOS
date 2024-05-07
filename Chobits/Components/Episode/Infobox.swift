//
//  Infobox.swift
//  Chobits
//
//  Created by Chuan Chuan on 2024/5/4.
//

import SwiftData
import SwiftUI

struct EpisodeInfobox: View {
  let subjectId: UInt
  let episodeId: UInt

  @Environment(\.dismiss) private var dismiss
  @EnvironmentObject var notifier: Notifier
  @EnvironmentObject var chii: ChiiClient

  @State private var updating: Bool = false

  @Query
  private var episodes: [Episode]
  private var episode: Episode? { episodes.first }

  init(subjectId: UInt, episodeId: UInt) {
    self.subjectId = subjectId
    self.episodeId = episodeId

    _episodes = Query(filter: #Predicate<Episode> { $0.id == episodeId })
  }

  func updateSingle(type: EpisodeCollectionType) async {
    if updating { return }
    updating = true
    do {
      try await chii.updateEpisodeCollection(episodeId: episodeId, type: type)
      dismiss()
    } catch {
      notifier.alert(error: error)
    }
    updating = false
  }

  func updateBatch() async {
    if updating { return }
    guard let episode = episode else {
      notifier.alert(message: "Episode not found")
      return
    }
    updating = true
    Task {
      do {
        try await chii.updateSubjectEpisodeCollection(
          subjectId: subjectId, updateTo: episode.sort, type: .collect)
        dismiss()
      } catch {
        notifier.alert(error: error)
      }
      updating = false
    }
  }

  var body: some View {
    ScrollView {
      VStack(alignment: .leading) {
        if let episode = episode {
          HStack {
            Text(episode.title).font(.headline).lineLimit(1)
            Text(episode.typeEnum.description)
              .font(.footnote)
              .foregroundStyle(.secondary)
              .overlay {
                RoundedRectangle(cornerRadius: 5)
                  .stroke(Color.secondary, lineWidth: 1)
                  .padding(.horizontal, -4)
                  .padding(.vertical, -2)
              }
            Spacer()
            if episode.comment > 0 {
              Label("讨论", systemImage: "bubble.fill").font(.caption).foregroundStyle(.secondary)
              Text("(+\(episode.comment))").font(.caption).foregroundStyle(.red)
            }
          }
          if chii.isAuthenticated {
            HStack {
              ForEach(episode.collectionTypeEnum.otherTypes()) { type in
                Button {
                  Task {
                    await updateSingle(type: type)
                  }
                } label: {
                  Text(type.action)
                }
              }.buttonStyle(.borderedProminent)
              Button {
                Task {
                  await updateBatch()
                }
              } label: {
                Text("看到")
              }
              .buttonStyle(.bordered)
              .foregroundColor(.red)
              Spacer()
              Text(episode.collectionTypeEnum.description).foregroundStyle(.red)
            }
            .font(.callout)
            .disabled(updating)
          }
          Divider()
          if !episode.name.isEmpty {
            Text("标题: \(episode.name)")
          }
          if !episode.nameCn.isEmpty {
            Text("中文标题: \(episode.nameCn)")
          }
          if !episode.airdateStr.isEmpty {
            Text("首播时间: \(episode.airdateStr)")
          }
          if !episode.duration.isEmpty {
            Text("时长: \(episode.duration)")
          }
          if episode.disc > 0 {
            Text("Disc: \(episode.disc)")
          }
          if !episode.desc.isEmpty {
            Text("描述:")
            Text(episode.desc).foregroundStyle(.secondary)
          }
          Spacer()
        }
      }
    }.padding()
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

  return EpisodeInfobox(subjectId: subject.id, episodeId: episodes.first!.id)
    .environmentObject(Notifier())
    .environmentObject(ChiiClient(container: container, mock: .anime))
    .modelContainer(container)
}
