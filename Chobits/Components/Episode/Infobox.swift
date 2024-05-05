//
//  Infobox.swift
//  Chobits
//
//  Created by Chuan Chuan on 2024/5/4.
//

import SwiftUI

struct EpisodeInfobox: View {
  let episode: Episode

  @EnvironmentObject var notifier: Notifier
  @EnvironmentObject var chii: ChiiClient
  @Environment(\.modelContext) private var modelContext

  @State private var updating: Bool = false

  func updateSingle(type: EpisodeCollectionType) async {
    updating = true
    do {
      try await chii.updateEpisodeCollection(episodeId: episode.id, type: type)
      updating = false
      episode.collection = type.rawValue
    } catch {
      updating = false
      notifier.alert(error: error)
    }
  }

  func updateBatch() async {
    updating = true
    let subjectId = episode.subjectId
    let sort = episode.sort
    let actor = BackgroundActor(container: modelContext.container)
    let predicate = #Predicate<Episode> {
      $0.subjectId == subjectId && $0.sort <= sort
    }
    do {
      let previous = try await actor.fetchData(predicate: predicate)
      let episodeIds = previous.map { $0.id }
      try await chii.updateSubjectEpisodeCollection(
        subjectId: episode.subjectId, episodeIds: episodeIds, type: EpisodeCollectionType.collect
      )
      for ep in previous {
        ep.collection = EpisodeCollectionType.collect.rawValue
      }
      try await actor.save()
      updating = false
    } catch {
      updating = false
      notifier.alert(error: error)
    }
  }

  var body: some View {
    ScrollView {
      VStack(alignment: .leading) {
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
            }
            Button {
              Task {
                await updateBatch()
              }
            } label: {
              Text("看到")
            }
            Spacer()
            Text(episode.collectionTypeEnum.description).foregroundStyle(.red)
          }
          .buttonStyle(.borderedProminent)
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
    }.padding()
  }
}

#Preview {
  EpisodeInfobox(episode: .preview)
    .environmentObject(ChiiClient(mock: .anime))
}
