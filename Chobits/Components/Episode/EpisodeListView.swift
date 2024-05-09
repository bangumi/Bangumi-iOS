//
//  EpisodeListView.swift
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

  @State private var now: Date = Date()
  @State private var offset: Int = 0
  @State private var main: Bool = true
  @State private var sortDesc: Bool = false
  @State private var exhausted: Bool = false
  @State private var selected: Episode? = nil
  @State private var loadedIdx: [Int: Bool] = [:]
  @State private var episodes: [EnumerateItem<Episode>] = []
  @State private var countMain: Int = 0
  @State private var countOther: Int = 0

  init(subjectId: UInt) {
    self.subjectId = subjectId
  }

  func loadCounts() async {
    do {
      let mainType = EpisodeType.main.rawValue
      let countMain = try await chii.db.fetchCount(
        predicate: #Predicate<Episode> {
          $0.subjectId == subjectId && $0.type == mainType
        })
      let countOther = try await chii.db.fetchCount(
        predicate: #Predicate<Episode> {
          $0.subjectId == subjectId && $0.type != mainType
        })
      self.countMain = countMain
      self.countOther = countOther
    } catch {
      notifier.alert(error: error)
    }
  }

  func fetch(limit: Int = 100) async -> [EnumerateItem<Episode>] {
    let sortBy =
      sortDesc ? SortDescriptor<Episode>(\.sort, order: .reverse) : SortDescriptor<Episode>(\.sort)
    let mainType = EpisodeType.main.rawValue
    var descriptor = FetchDescriptor<Episode>(
      predicate: #Predicate<Episode> {
        if main {
          $0.subjectId == subjectId && $0.type == mainType
        } else {
          $0.subjectId == subjectId && $0.type != mainType
        }
      }, sortBy: [sortBy])
    descriptor.fetchLimit = limit
    descriptor.fetchOffset = offset
    do {
      let episodes = try await chii.db.fetchData(descriptor)
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
    loadedIdx.removeAll()
    episodes.removeAll()
    let episodes = await fetch()
    self.episodes.append(contentsOf: episodes)
  }

  func loadNextPage(idx: Int) async {
    if exhausted {
      return
    }
    if idx != offset - 10 {
      return
    }
    if loadedIdx[idx, default: false] {
      return
    }
    loadedIdx[idx] = true
    let episodes = await fetch()
    self.episodes.append(contentsOf: episodes)
  }

  var body: some View {
    HStack {
      Picker("Episode Type", selection: $main) {
        Text("本篇(\(countMain))").tag(true)
        Text("其他(\(countOther))").tag(false)
      }
      .pickerStyle(.segmented)
      .onChange(of: main) {
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
                    }
                    .padding(.horizontal, 2)
                    .strikethrough(episode.collection == EpisodeCollectionType.dropped.rawValue)
                } else {
                  if main {
                    if episode.airdate > now {
                      RoundedRectangle(cornerRadius: 5)
                        .stroke(.secondary, lineWidth: 1)
                        .frame(width: 40, height: 24)
                        .overlay {
                          Text("未播")
                            .foregroundStyle(.secondary)
                        }
                        .padding(.horizontal, 2)
                    } else {
                      RoundedRectangle(cornerRadius: 5)
                        .stroke(.primary, lineWidth: 1)
                        .frame(width: 40, height: 24)
                        .overlay {
                          Text("已播")
                            .foregroundStyle(.primary)
                        }
                        .padding(.horizontal, 2)
                    }
                  } else {
                    RoundedRectangle(cornerRadius: 5)
                      .stroke(.primary, lineWidth: 1)
                      .frame(width: 40, height: 24)
                      .overlay {
                        Text(episode.typeEnum.description)
                          .foregroundStyle(.primary)
                      }
                      .padding(.horizontal, 2)
                  }
                }

                VStack(alignment: .leading) {
                  if !episode.nameCn.isEmpty {
                    Text(episode.nameCn)
                      .lineLimit(1)
                      .font(.subheadline)
                  }
                  HStack {
                    Text("时长:\(episode.duration)")
                    Spacer()
                    Text("首播:\(episode.airdateStr)")
                    Spacer()
                    Text("讨论:+\(episode.comment)")
                  }
                  .font(.footnote)
                  .foregroundStyle(.secondary)
                }
                Spacer()
              }
            }.padding(.vertical, 5)
          }
          .padding(5)
          .onAppear {
            Task {
              await loadNextPage(idx: item.idx)
            }
          }
        }
      }
    }
    .navigationBarTitle("章节列表")
    .padding(.horizontal, 16)
    .buttonStyle(.plain)
    .animation(.default, value: episodes)
    .onAppear {
      Task {
        await loadCounts()
        await load()
      }
    }
    .sheet(
      item: $selected,
      content: { episode in
        EpisodeInfoboxView(subjectId: subjectId, episodeId: episode.id)
          .presentationDragIndicator(.visible)
          .presentationDetents(.init([.medium, .large]))
      }
    )
  }
}

#Preview {
  let container = mockContainer()

  let subject = Subject.previewAnime
  container.mainContext.insert(subject)
  let episodes = Episode.previewList
  for episode in episodes {
    container.mainContext.insert(episode)
  }

  return EpisodeListView(subjectId: subject.id)
    .environmentObject(Notifier())
    .environment(ChiiClient(container: container, mock: .anime))
    .modelContainer(container)
}
