//
//  Episode.swift
//  Chobits
//
//  Created by Chuan Chuan on 2024/5/5.
//

import SwiftData
import SwiftUI

struct EpisodeListView: View {
  let subject: Subject

  @EnvironmentObject var notifier: Notifier
  @Environment(\.modelContext) var modelContext

  @State private var now: Date = Date()
  @State private var offset: Int = 0
  @State private var type: EpisodeType = .main
  @State private var sortDesc: Bool = false
  @State private var exhausted: Bool = false
  @State private var selected: Episode? = nil
  @State private var episodes: [Episode] = []

  func fetch(limit: Int = 50) async -> [Episode] {
    let actor = BackgroundActor(container: modelContext.container)
    let sortBy =
      sortDesc ? SortDescriptor<Episode>(\.sort, order: .reverse) : SortDescriptor<Episode>(\.sort)
    var descriptor = FetchDescriptor<Episode>(
      predicate: #Predicate {
        $0.subjectId == subject.id && $0.type == type.rawValue
      }, sortBy: [sortBy])
    descriptor.fetchLimit = limit
    descriptor.fetchOffset = offset
    do {
      let episodes = try await actor.fetchData(descriptor: descriptor)
      if episodes.count < limit {
        exhausted = true
      }
      offset += limit
      return episodes
    } catch {
      notifier.alert(error: error)
    }
    return []
  }

  func load() async {
    offset = 0
    exhausted = false
    episodes.removeAll()
    let episodes = await fetch()
    self.episodes.append(contentsOf: episodes)
  }

  func loadNextPage(current: Episode) async {
    if exhausted {
      return
    }
    let thresholdIndex = episodes.index(episodes.endIndex, offsetBy: -2)
    let currentIndex = episodes.firstIndex(where: { $0.id == current.id })
    if currentIndex != thresholdIndex {
      return
    }
    let episodes = await fetch()
    self.episodes.append(contentsOf: episodes)
  }

  var body: some View {
    HStack {
      Picker("Episode Type", selection: $type) {
        ForEach(EpisodeType.allTypes()) { et in
          Text("\(et.description)").tag(et)
        }
      }
      .pickerStyle(.segmented)
      .onChange(of: type) {
        Task {
          await load()
        }
      }
      Spacer()
      Toggle(isOn: $sortDesc) {
      }
      .frame(width: 50)
      .toggleStyle(.switch)
      .onChange(of: sortDesc) {
        Task {
          await load()
        }
      }
    }.padding(.horizontal, 16)
    ScrollView {
      LazyVStack {
        ForEach(episodes) { episode in
          Button {
            selected = episode
          } label: {
            VStack(alignment: .leading) {
              Text(episode.item.title)
                .font(.headline)
                .lineLimit(1)
              HStack {
                if episode.airdateDate > now {
                  Text("未播")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .overlay {
                      RoundedRectangle(cornerRadius: 5)
                        .stroke(Color.secondary, lineWidth: 1)
                        .padding(.horizontal, -4)
                        .padding(.vertical, -2)
                    }
                    .padding(.horizontal, 10)
                } else {
                  Text("已播")
                    .font(.callout)
                    .overlay {
                      RoundedRectangle(cornerRadius: 5)
                        .stroke(Color.secondary, lineWidth: 1)
                        .padding(.horizontal, -4)
                        .padding(.vertical, -2)
                    }
                    .padding(.horizontal, 10)
                }
                VStack(alignment: .leading) {
                  Text(episode.nameCn)
                    .lineLimit(1)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                  Text("时长:\(episode.duration) / 首播:\(episode.airdate) / 讨论:+\(episode.comment)")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                }
                Spacer()
              }
            }
            .padding(5)
          }
        }
      }
    }
    .padding(.horizontal, 16)
    .buttonStyle(.plain)
    .animation(.default, value: episodes)
    .task {
      await load()
    }
    .sheet(
      item: $selected,
      content: { episode in
        EpisodeInfobox(episode: episode)
          .presentationDragIndicator(.visible)
          .presentationDetents(.init([.medium, .large]))
      })

  }
}

#Preview {
  let config = ModelConfiguration(isStoredInMemoryOnly: true)
  let container = try! ModelContainer(
    for: UserSubjectCollection.self, Subject.self, Episode.self, EpisodeCollection.self,
    configurations: config)
  let episodes = Episode.previewList
  for episode in episodes {
    container.mainContext.insert(episode)
  }

  return EpisodeListView(subject: .previewAnime)
    .environmentObject(Notifier())
    .modelContainer(container)
}
