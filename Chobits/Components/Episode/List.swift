//
//  Episode.swift
//  Chobits
//
//  Created by Chuan Chuan on 2024/5/5.
//

import OSLog
import SwiftData
import SwiftUI

struct EpisodeListView: View {
  let subjectId: UInt

  @EnvironmentObject var notifier: Notifier
  @EnvironmentObject var chii: ChiiClient
  @Environment(\.modelContext) var modelContext

  @State private var now: Date = Date()
  @State private var offset: Int = 0
  @State private var type: EpisodeType = .main
  @State private var sortDesc: Bool = false
  @State private var exhausted: Bool = false
  @State private var selected: Episode? = nil
  @State private var episodes: [EnumerateItem<Episode>] = []
  @State private var counts: [EpisodeType: Int] = [:]

  func loadCounts() async {
    let actor = BackgroundActor(container: modelContext.container)
    do {
      for type in EpisodeType.allTypes() {
        let count = try await actor.fetchCount(
          predicate: #Predicate<Episode> {
            $0.subjectId == subjectId && $0.type == type.rawValue
          })
        counts[type] = count
      }
    } catch {
      notifier.alert(error: error)
    }
  }

  func fetch(limit: Int = 100) async -> [EnumerateItem<Episode>] {
    let actor = BackgroundActor(container: modelContext.container)
    let sortBy =
      sortDesc ? SortDescriptor<Episode>(\.sort, order: .reverse) : SortDescriptor<Episode>(\.sort)
    var descriptor = FetchDescriptor<Episode>(
      predicate: #Predicate {
        $0.subjectId == subjectId && $0.type == type.rawValue
      }, sortBy: [sortBy])
    descriptor.fetchLimit = limit
    descriptor.fetchOffset = offset
    do {
      let episodes = try await actor.fetchData(descriptor: descriptor)
      if episodes.count < limit {
        exhausted = true
      }
      let result = episodes.enumerated().map { (idx, episode) in
        EnumerateItem(idx: idx + offset, inner: episode)
      }
      offset += limit
      return result
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

  func loadNextPage(idx: Int) async {
    if exhausted {
      return
    }
    if idx != episodes.count - 10 {
      return
    }
    let episodes = await fetch()
    self.episodes.append(contentsOf: episodes)
  }

  func pickerHeader(type: EpisodeType) -> String {
    let count = counts[type, default: 0]
    if count == 0 {
      return "\(type.description)"
    } else {
      return "\(type.description)(\(count))"
    }
  }

  var body: some View {
    HStack {
      Picker("Episode Type", selection: $type) {
        ForEach(EpisodeType.allTypes()) { et in
          Text(pickerHeader(type: et)).tag(et)
        }
      }
      .pickerStyle(.segmented)
      .onChange(of: type) {
        Task {
          await load()
        }
      }
      Spacer()
      Image(systemName: sortDesc ? "arrow.down.circle.fill" : "arrow.up.circle.fill")
        .foregroundStyle(sortDesc ? .accent : .secondary)
        .font(.title)
        .sensoryFeedback(.selection, trigger: sortDesc)
        .onTapGesture {
          self.sortDesc.toggle()
        }
        .onChange(of: sortDesc) {
          Task {
            await load()
          }
        }
    }.padding(.horizontal, 16)
    ScrollView {
      LazyVStack {
        ForEach(episodes, id: \.idx) { item in
          let episode = item.inner
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
          .task(priority: .background) {
            await loadNextPage(idx: item.idx)
          }
        }
      }
    }
    .padding(.horizontal, 16)
    .buttonStyle(.plain)
    .animation(.default, value: episodes)
    .task(priority: .background) {
      await loadCounts()
      await load()
    }
    .sheet(
      item: $selected,
      content: { episode in
        EpisodeInfobox(subjectId: subjectId, episodeId: episode.id)
          .presentationDragIndicator(.visible)
          .presentationDetents(.init([.medium, .large]))
      }
    )
  }
}

#Preview {
  let config = ModelConfiguration(isStoredInMemoryOnly: true)
  let container = try! ModelContainer(
    for: UserSubjectCollection.self, Subject.self, Episode.self,
    configurations: config)

  let subject = Subject.previewAnime
  container.mainContext.insert(subject)
  let episodes = Episode.previewList
  for episode in episodes {
    container.mainContext.insert(episode)
  }

  return EpisodeListView(subjectId: subject.id)
    .environmentObject(Notifier())
    .environment(ChiiClient(mock: .anime))
    .modelContainer(container)
}
