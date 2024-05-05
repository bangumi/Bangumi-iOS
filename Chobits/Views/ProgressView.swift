//
//  ProgressView.swift
//  Chobits
//
//  Created by Chuan Chuan on 2024/4/19.
//

import OSLog
import SwiftData
import SwiftUI

struct ChiiProgressView: View {
  @EnvironmentObject var notifier: Notifier
  @EnvironmentObject var chii: ChiiClient
  @EnvironmentObject var navState: NavState
  @Environment(\.modelContext) private var modelContext

  @State private var subjectType = SubjectType.unknown
  @State private var offset: Int = 0
  @State private var exhausted: Bool = false
  @State private var counts: [SubjectType: Int] = [:]
  @State private var collections: [EnumerateItem<UserSubjectCollection>] = []

  func loadCounts() async {
    let actor = BackgroundActor(container: modelContext.container)
    let doingType = CollectionType.do.rawValue
    do {
      for type in SubjectType.progressTypes() {
        let count = try await actor.fetchCount(
          predicate: #Predicate<UserSubjectCollection> {
            $0.type == doingType && $0.subjectType == type.rawValue
          })
        Logger.collection.info("progress type: \(type.name), count: \(count)")
        counts[type] = count
      }
      let totalCount = try await actor.fetchCount(
        predicate: #Predicate<UserSubjectCollection> {
          $0.type == doingType
        })
      Logger.collection.info("progress total: \(totalCount)")
      counts[.unknown] = totalCount
    } catch {
      notifier.alert(error: error)
    }
  }

  func fetch(limit: Int = 20) async -> [EnumerateItem<UserSubjectCollection>] {
    let actor = BackgroundActor(container: modelContext.container)
    let stype = subjectType.rawValue
    let doingType = CollectionType.do.rawValue
    var descriptor = FetchDescriptor<UserSubjectCollection>(
      predicate: #Predicate<UserSubjectCollection> {
        (stype == 0 || $0.subjectType == stype) && $0.type == doingType
      },
      sortBy: [
        SortDescriptor(\.updatedAt, order: .reverse)
      ])
    descriptor.fetchLimit = limit
    descriptor.fetchOffset = offset
    do {
      let collections = try await actor.fetchData(descriptor: descriptor)
      if collections.count < limit {
        exhausted = true
      }
      let result = collections.enumerated().map { (idx, collection) in
        EnumerateItem(idx: idx + offset, inner: collection)
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
    collections.removeAll()
    let collections = await fetch()
    self.collections.append(contentsOf: collections)
  }

  func loadNextPage(idx: Int) async {
    if exhausted {
      return
    }
    if idx != collections.count - 10 {
      return
    }
    let collections = await fetch()
    self.collections.append(contentsOf: collections)
  }

  func updateCollections(type: SubjectType?) async {
    let actor = BackgroundActor(container: modelContext.container)
    var offset: Int = 0
    let limit: Int = 100
    do {
      while true {
        let response = try await chii.getSubjectCollections(
          subjectType: type, limit: limit, offset: offset)
        if response.data.isEmpty {
          break
        }
        for collection in response.data {
          await actor.insert(data: collection, background: true)
        }
        offset += limit
        if offset > response.total {
          break
        }
      }
      try await actor.save()
    } catch {
      notifier.alert(error: error)
    }
  }

  var body: some View {
    if chii.isAuthenticated {
      NavigationStack(path: $navState.progressNavigation) {
        if counts.isEmpty {
          ProgressView().task {
            Logger.collection.info("loading progress")
            await loadCounts()
            if counts.allSatisfy({ $0.value == 0 }) {
              Logger.collection.info("updating collections for all types")
              await updateCollections(type: nil)
              await loadCounts()
            }
            await load()
          }
        } else {
          VStack {
            Picker("Subject Type", selection: $subjectType) {
              ForEach(SubjectType.progressTypes()) { type in
                Text("\(type.description)(\(counts[type, default: 0]))").tag(type)
              }
            }
            .pickerStyle(.segmented)
            .onChange(of: subjectType) {
              Task {
                await load()
              }
            }
            ScrollView {
              LazyVStack(alignment: .leading, spacing: 10) {
                ForEach(collections, id: \.idx) { item in
                  NavigationLink(value: NavDestination.subject(subjectId: item.inner.subjectId)) {
                    UserCollectionRow(collection: item.inner)
                  }
                  .buttonStyle(PlainButtonStyle())
                  .task(priority: .background) {
                    await loadNextPage(idx: item.idx)
                  }
                }
              }
            }
            .animation(.easeInOut, value: subjectType)
            .refreshable {
              Task(priority: .background) {
                if counts.isEmpty {
                  // do not fresh when page loads
                  return
                }
                Logger.collection.info("updating collections for \(subjectType.name)")
                await updateCollections(type: subjectType)
                await loadCounts()
                await load()
              }
            }
          }
          .animation(.default, value: collections)
          .padding()
          .navigationDestination(for: NavDestination.self) { nav in
            switch nav {
            case .subject(let sid):
              SubjectView(subjectId: sid)
            case .episodeList(let sid):
              EpisodeListView(subjectId: sid)
            }
          }
        }
      }
    } else {
      AuthView(slogan: "使用 Bangumi 管理观看进度")
    }
  }
}
