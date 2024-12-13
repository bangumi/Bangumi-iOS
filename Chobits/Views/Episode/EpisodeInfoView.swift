//
//  EpisodeInfoView.swift
//  Chobits
//
//  Created by Chuan Chuan on 2024/12/13.
//

import SwiftData
import SwiftUI

struct EpisodeInfoView: View {
  @ObservableModel var episode: Episode

  @AppStorage("isolationMode") var isolationMode: Bool = false

  var body: some View {
    VStack(alignment: .leading, spacing: 5) {
      HStack(alignment: .bottom) {
        Text(episode.title).font(.title3).lineLimit(1)
        BorderView {
          Text(episode.typeEnum.description)
            .font(.footnote)
            .foregroundStyle(.secondary)
            .fixedSize()
        }
        Spacer()
        if episode.comment > 0 && !isolationMode {
          Label("讨论", systemImage: "bubble.fill")
            .font(.caption)
            .foregroundStyle(.secondary)
            .fixedSize()
          Text("(+\(episode.comment))")
            .font(.caption)
            .foregroundStyle(.red)
            .fixedSize()
        }
      }
      Divider()
      if !episode.name.isEmpty {
        Text("标题: \(episode.name)")
      }
      if !episode.nameCN.isEmpty {
        Text("中文标题: \(episode.nameCN)")
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

  return ScrollView {
    EpisodeInfoView(episode: episodes.first!)
      .modelContainer(container)
  }
}
