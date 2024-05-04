//
//  EpisodeInfobox.swift
//  Chobits
//
//  Created by Chuan Chuan on 2024/5/4.
//

import SwiftUI

struct EpisodeInfobox: View {
  let episode: EpisodeItem
  let collection: EpisodeCollection?

  @EnvironmentObject var notifier: Notifier
  @EnvironmentObject var chii: ChiiClient
  @Environment(\.modelContext) private var modelContext

  @State private var updating: Bool = false

  init(collection: EpisodeCollection) {
    self.episode = collection.episode
    self.collection = collection
  }

  init(episode: Episode) {
    self.episode = episode.item
    self.collection = nil
  }

  var epNumber: String {
    if let ep = episode.ep {
      return ep.episodeDisplay
    } else {
      return episode.sort.episodeDisplay
    }
  }

  func updateSingle(type: EpisodeCollectionType) async {
    guard let collection = collection else {
      return
    }
    updating = true
    do {
      try await chii.updateEpisodeCollection(episodeId: collection.episode.id, type: type)
      updating = false
      collection.type = type.rawValue
    } catch {
      updating = false
      notifier.alert(error: error)
    }
  }

  func updateBatch() async {
    guard let collection = collection else {
      return
    }
    updating = true
    let actor = BackgroundActor(container: modelContext.container)
    let predicate = #Predicate<EpisodeCollection> {
      $0.subjectId == collection.subjectId && $0.episode.sort <= collection.episode.sort
    }
    do {
      let previous = try await actor.fetchData(predicate: predicate)
      let episodeIds = previous.map { $0.episode.id }
      try await chii.updateSubjectEpisodeCollection(
        subjectId: collection.subjectId, episodeIds: episodeIds, type: EpisodeCollectionType.collect
      )
      for collect in previous {
        collect.type = EpisodeCollectionType.collect.rawValue
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
          switch episode.type {
          case .main:
            Text("ep.\(epNumber) \(episode.name)").font(.headline).lineLimit(1)
          case .sp:
            Text("sp.\(episode.sort.episodeDisplay) \(episode.name)").font(.headline).lineLimit(1)
          case .op:
            Text("op.\(episode.sort.episodeDisplay) \(episode.name)").font(.headline).lineLimit(1)
          case .ed:
            Text("ed.\(episode.sort.episodeDisplay) \(episode.name)").font(.headline).lineLimit(1)
          }
          Text(episode.type.description)
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
        if let collection = collection {
          HStack {
            ForEach(collection.typeEnum.otherTypes()) { type in
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
            Text(collection.typeEnum.description).foregroundStyle(.accent)
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
        if !episode.airdate.isEmpty {
          Text("首播时间: \(episode.airdate)")
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
  EpisodeInfobox(collection: .preview)
    .environmentObject(ChiiClient(mock: .anime))
}
