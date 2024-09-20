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

  @Environment(Notifier.self) private var notifier
  @Environment(ChiiClient.self) private var chii
  @Environment(\.modelContext) var modelContext

  @State private var now: Date = Date()
  @State private var offset: Int = 0
  @State private var main: Bool = true
  @State private var filterCollection: Bool = false
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
    let mainType = EpisodeType.main.rawValue
    do {
      let mainDesc = FetchDescriptor<Episode>(
        predicate: #Predicate<Episode> {
          $0.subjectId == subjectId && $0.type == mainType
        })
      let countMain = try modelContext.fetchCount(mainDesc)
      self.countMain = countMain

      let otherDesc = FetchDescriptor<Episode>(
        predicate: #Predicate<Episode> {
          $0.subjectId == subjectId && $0.type != mainType
        })
      let countOther = try modelContext.fetchCount(otherDesc)
      self.countOther = countOther
    } catch {
      notifier.alert(error: error)
    }
  }

  func fetch(limit: Int = 100) async -> [EnumerateItem<Episode>] {
    let sortBy =
      sortDesc ? SortDescriptor<Episode>(\.sort, order: .reverse) : SortDescriptor<Episode>(\.sort)
    let zero: UInt8 = 0
    let mainType = EpisodeType.main.rawValue
    var descriptor = FetchDescriptor<Episode>(
      predicate: #Predicate<Episode> {
        if main {
          if filterCollection {
            $0.subjectId == subjectId && $0.type == mainType && $0.collection == zero
          } else {
            $0.subjectId == subjectId && $0.type == mainType
          }
        } else {
          if filterCollection {
            $0.subjectId == subjectId && $0.type != mainType && $0.collection == zero
          } else {
            $0.subjectId == subjectId && $0.type != mainType
          }
        }
      }, sortBy: [sortBy])
    descriptor.fetchLimit = limit
    descriptor.fetchOffset = offset
    do {
      let episodes = try modelContext.fetch(descriptor)
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
      Image(systemName: filterCollection ? "eye.slash.circle.fill" : "eye.circle.fill")
        .foregroundStyle(filterCollection ? .accent : .secondary)
        .font(.title)
        .sensoryFeedback(.selection, trigger: filterCollection)
        .onTapGesture {
          self.filterCollection.toggle()
        }
        .onChange(of: filterCollection) {
          Task {
            await load()
          }
        }
      Spacer()
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
    }.padding(.horizontal, 8)
    ScrollView {
      LazyVStack {
        ForEach(episodes, id: \.inner.self) { item in
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
                        .font(.footnote)
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
                            .font(.footnote)
                        }
                        .padding(.horizontal, 2)
                    } else {
                      RoundedRectangle(cornerRadius: 5)
                        .stroke(.primary, lineWidth: 1)
                        .frame(width: 40, height: 24)
                        .overlay {
                          Text("已播")
                            .foregroundStyle(.primary)
                            .font(.footnote)
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
                          .font(.footnote)
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
                    Label("\(episode.duration)", systemImage: "clock")
                    Label("\(episode.airdateStr)", systemImage: "calendar")
                    Spacer()
                    Label("+\(episode.comment)", systemImage: "bubble")
                  }
                  .font(.footnote)
                  .foregroundStyle(.secondary)
                  Divider()
                }
                Spacer()
              }
            }
          }
          .padding(.horizontal, 8)
          .onAppear {
            Task {
              await loadNextPage(idx: item.idx)
            }
          }
        }
        if exhausted {
          Divider()
          HStack {
            Spacer()
            Text("没有更多了")
              .font(.footnote)
              .foregroundStyle(.secondary)
            Spacer()
          }
        }
      }
    }
    .padding(.horizontal, 8)
    .buttonStyle(.plain)
    .animation(.default, value: episodes)
    .navigationTitle("章节列表")
    .navigationBarTitleDisplayMode(.inline)
    .toolbar {
      ToolbarItem(placement: .automatic) {
        Image(systemName: "list.bullet.circle").foregroundStyle(.secondary)
      }
    }
    .onAppear {
      Task {
        await loadCounts()
        await load()
      }
    }
    .sheet(
      item: $selected,
      content: { episode in
        EpisodeCollectionBoxView(subjectId: subjectId, episodeId: episode.episodeId)
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

  return EpisodeListView(subjectId: subject.subjectId)
    .environment(Notifier())
    .environment(ChiiClient(container: container, mock: .anime))
    .modelContainer(container)
}
