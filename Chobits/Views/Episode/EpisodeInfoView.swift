//
//  EpisodeInfoView.swift
//  Chobits
//
//  Created by Chuan Chuan on 2024/12/13.
//

import SwiftData
import SwiftUI

struct EpisodeInfoView: View {
  @AppStorage("isolationMode") var isolationMode: Bool = false

  @Environment(Episode.self) var episode

  func field(name: String, value: String) -> AttributedString {
    var text = AttributedString(name + ": ")
    var value = AttributedString(value)
    value.foregroundColor = .secondary
    text.append(value)
    return text
  }

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
        Text(field(name: "标题", value: episode.name))
      }
      if !episode.nameCN.isEmpty {
        Text(field(name: "中文标题", value: episode.nameCN))
      }
      if !episode.airdate.isEmpty {
        Text(field(name: "首播时间", value: episode.airdate))
      }
      if !episode.duration.isEmpty {
        Text(field(name: "时长", value: episode.duration))
      }
      if episode.disc > 0 {
        Text(field(name: "Disc", value: "\(episode.disc)"))
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
    EpisodeInfoView().environment(episodes.first!)
      .modelContainer(container)
  }
}
