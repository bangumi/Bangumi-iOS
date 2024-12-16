//
//  EpisodeRowView.swift
//  Chobits
//
//  Created by Chuan Chuan on 2024/12/13.
//

import SwiftData
import SwiftUI

struct EpisodeRowView: View {
  @AppStorage("isolationMode") var isolationMode: Bool = false
  @AppStorage("isAuthenticated") var isAuthenticated: Bool = false

  @Environment(Episode.self) var episode

  @State private var now: Date = Date()

  var body: some View {
    VStack(alignment: .leading) {
      NavigationLink(value: NavDestination.episode(episode.subjectId, episode.episodeId)) {
        Text(episode.title)
          .font(.headline)
          .lineLimit(1)
      }.buttonStyle(.navLink)
      HStack {
        if isAuthenticated && episode.collectionTypeEnum != .none {
          BorderView(color: Color(hex: episode.borderColor), padding: 4) {
            Text("\(episode.collectionTypeEnum.description)")
              .foregroundStyle(Color(hex: episode.textColor))
              .font(.footnote)
          }
          .padding(2)
          .strikethrough(episode.collection == EpisodeCollectionType.dropped.rawValue)
          .background {
            RoundedRectangle(cornerRadius: 5)
              .fill(Color(hex: episode.backgroundColor))
          }
        } else {
          if episode.typeEnum == .main {
            if episode.air > now {
              BorderView(padding: 4) {
                Text("未播")
                  .foregroundStyle(.secondary)
                  .font(.footnote)
              }
            } else {
              BorderView(color: .primary, padding: 4) {
                Text("已播")
                  .foregroundStyle(.primary)
                  .font(.footnote)
              }
            }
          } else {
            BorderView(color: .primary, padding: 4) {
              Text(episode.typeEnum.description)
                .foregroundStyle(.primary)
                .font(.footnote)
            }
          }
        }
        VStack(alignment: .leading) {
          HStack {
            Label("\(episode.duration)", systemImage: "clock")
            Label("\(episode.airdate)", systemImage: "calendar")
            Spacer()
            if !isolationMode {
              Label("+\(episode.comment)", systemImage: "bubble")
            }
          }
          .font(.footnote)
          .foregroundStyle(.secondary)
          Divider()
        }
        Spacer()
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
    LazyVStack {
      EpisodeRowView().environment(episodes.first!)
        .modelContainer(container)
    }.padding()
  }
}
