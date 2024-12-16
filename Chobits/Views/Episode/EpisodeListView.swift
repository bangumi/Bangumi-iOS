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
  let subjectId: Int

  @AppStorage("isolationMode") var isolationMode: Bool = false
  @AppStorage("isAuthenticated") var isAuthenticated: Bool = false

  @Environment(\.modelContext) var modelContext

  @State private var offset: Int = 0
  @State private var main: Bool = true
  @State private var filterCollection: Bool = false
  @State private var sortDesc: Bool = false
  @State private var exhausted: Bool = false
  @State private var loadedIdx: [Int: Bool] = [:]
  @State private var episodes: [EnumerateItem<Episode>] = []
  @State private var countMain: Int = 0
  @State private var countOther: Int = 0

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
      Notifier.shared.alert(error: error)
    }
  }

  func fetch(limit: Int = 100) async -> [EnumerateItem<Episode>] {
    let sortBy =
      sortDesc ? SortDescriptor<Episode>(\.sort, order: .reverse) : SortDescriptor<Episode>(\.sort)
    let mainType = EpisodeType.main.rawValue
    var descriptor = FetchDescriptor<Episode>(
      predicate: #Predicate<Episode> {
        if main {
          if filterCollection {
            $0.subjectId == subjectId && $0.type == mainType && $0.collection == 0
          } else {
            $0.subjectId == subjectId && $0.type == mainType
          }
        } else {
          if filterCollection {
            $0.subjectId == subjectId && $0.type != mainType && $0.collection == 0
          } else {
            $0.subjectId == subjectId && $0.type != mainType
          }
        }
      }, sortBy: [sortBy])
    descriptor.fetchLimit = limit
    descriptor.fetchOffset = offset
    do {
      let resp = try modelContext.fetch(descriptor)
      if resp.count < limit {
        exhausted = true
      }
      let result = resp.enumerated().map { (idx, item) in
        EnumerateItem(idx: idx + offset, inner: item)
      }
      offset += limit
      return result
    } catch {
      Notifier.shared.alert(error: error)
    }
    return []
  }

  func load() async {
    offset = 0
    exhausted = false
    loadedIdx.removeAll()
    episodes.removeAll()
    let items = await fetch()
    self.episodes.append(contentsOf: items)
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
    let items = await fetch()
    self.episodes.append(contentsOf: items)
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
      LazyVStack(spacing: 10) {
        ForEach(episodes, id: \.inner.self) { item in
          EpisodeRowView().environment(item.inner)
            .onAppear {
              Task {
                await loadNextPage(idx: item.idx)
              }
            }
        }
        if exhausted {
          HStack {
            Spacer()
            Text("没有更多了")
              .font(.footnote)
              .foregroundStyle(.secondary)
            Spacer()
          }
        }
      }.padding(.horizontal, 8)
    }
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
  }
}

#Preview {
  let container = mockContainer()

  let subject = Subject.previewAnime
  container.mainContext.insert(subject)
  let episodes = Episode.previewCollections
  for episode in episodes {
    container.mainContext.insert(episode)
  }

  return EpisodeListView(subjectId: subject.subjectId)
    .modelContainer(container)
}
