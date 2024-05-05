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
  @EnvironmentObject var chii: ChiiClient
  @Environment(\.modelContext) var modelContext

  @State private var now: Date = Date()
  @State private var offset: Int = 0
  @State private var type: EpisodeType = .main
  @State private var sortDesc: Bool = false
  @State private var exhausted: Bool = false
  @State private var selected: Episode? = nil
  @State private var episodes: [Episode] = []
  @State private var counts: [EpisodeType: Int] = [:]

  func loadCounts() async {
    let actor = BackgroundActor(container: modelContext.container)
    do {
      for type in EpisodeType.allTypes() {
        let count = try await actor.fetchCount(
          predicate: #Predicate<Episode> {
            $0.subjectId == subject.id && $0.type == type.rawValue
          })
        counts[type] = count
      }
    } catch {
      notifier.alert(error: error)
    }
  }

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
    print("checking load next page for: \(current.title)")
    let thresholdIndex = episodes.index(episodes.endIndex, offsetBy: -8)
    let currentIndex = episodes.firstIndex(where: { $0.id == current.id })
    if currentIndex != thresholdIndex {
      return
    }
    print("loading next page for: \(current.title)")
    let episodes = await fetch()
    self.episodes.append(contentsOf: episodes)
  }

  var body: some View {
    HStack {
      Picker("Episode Type", selection: $type) {
        ForEach(EpisodeType.allTypes()) { et in
          Text("\(et.description)(\(counts[et, default: 0]))").tag(et)
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
              Text(episode.title)
                .font(.headline)
                .lineLimit(1)
              HStack {
                if chii.isAuthenticated && episode.collectionTypeEnum != .none {
                  RoundedRectangle(cornerRadius: 5)
                    .fill(Color(hex: episode.backgroundColor))
                    .stroke(Color(hex: episode.borderColor), lineWidth: 1)
                    .frame(width: 40, height: 24)
                    .overlay {
                      Text("\(episode.collectionTypeEnum.description)")
                        .foregroundStyle(Color(hex: episode.textColor))
                        .font(.callout)
                    }
                    .padding(.horizontal, 2)
                    .strikethrough(episode.collection == EpisodeCollectionType.dropped.rawValue)
                } else {
                  if episode.airdate > now {
                    RoundedRectangle(cornerRadius: 5)
                      .stroke(.secondary, lineWidth: 1)
                      .frame(width: 40, height: 24)
                      .overlay {
                        Text("未播")
                          .foregroundStyle(.secondary)
                          .font(.callout)
                      }
                      .padding(.horizontal, 2)
                  } else {
                    RoundedRectangle(cornerRadius: 5)
                      .stroke(.primary, lineWidth: 1)
                      .frame(width: 40, height: 24)
                      .overlay {
                        Text("已播")
                          .foregroundStyle(.primary)
                          .font(.callout)
                      }
                      .padding(.horizontal, 2)
                  }
                }
                VStack(alignment: .leading) {
                  if !episode.nameCn.isEmpty {
                    Text(episode.nameCn)
                      .lineLimit(1)
                      .font(.subheadline)
                      .foregroundStyle(.secondary)
                  }
                  Text("时长:\(episode.duration) / 首播:\(episode.airdateStr) / 讨论:+\(episode.comment)")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                }
                Spacer()
              }
            }
          }
          .padding(5)
          .task {
            await loadNextPage(current: episode)
          }
        }
      }
    }
    .padding(.horizontal, 16)
    .buttonStyle(.plain)
    .animation(.default, value: episodes)
    .task {
      await loadCounts()
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
    for: UserSubjectCollection.self, Subject.self, Episode.self,
    configurations: config)
  let episodes = Episode.previewList
  for episode in episodes {
    container.mainContext.insert(episode)
  }

  return EpisodeListView(subject: .previewAnime)
    .environmentObject(Notifier())
    .environment(ChiiClient(mock: .anime))
    .modelContainer(container)
}
