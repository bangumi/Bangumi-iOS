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
  @Environment(\.modelContext) var modelContext

  @State private var loaded: Bool = false
  @State private var subjectType = SubjectType.unknown
  @State private var offset: Int = 0
  @State private var exhausted: Bool = false
  @State private var loadedIdx: [Int: Bool] = [:]
  @State private var counts: [SubjectType: Int] = [:]
  @State private var collections: [EnumerateItem<(UserSubjectCollection)>] = []

  func loadCounts() async {
    let doingType = CollectionType.do.rawValue
    let fetcher = BackgroundFetcher(modelContext.container)
    do {
      for type in SubjectType.progressTypes() {
        if type == .unknown {
          continue
        }
        let count = try await fetcher.fetchCount(#Predicate<UserSubjectCollection> {
            $0.type == doingType && $0.subjectType == type.rawValue
          })
        counts[type] = count
      }
      let totalCount = try await fetcher.fetchCount(#Predicate<UserSubjectCollection> {
          $0.type == doingType
        })
      Logger.collection.info("load progress total count: \(totalCount)")
      counts[.unknown] = totalCount
    } catch {
      notifier.alert(error: error)
    }
  }

  func fetch(limit: Int = 20) async -> [EnumerateItem<UserSubjectCollection>] {
    let stype = subjectType.rawValue
    let doingType = CollectionType.do.rawValue
    let fetcher = BackgroundFetcher(modelContext.container)
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
      let collections = try await fetcher.fetchData(descriptor)
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
    loadedIdx.removeAll()
    collections.removeAll()
    let collections = await fetch()
    self.collections.append(contentsOf: collections)
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
    let collections = await fetch()
    self.collections.append(contentsOf: collections)
  }

  func updateCollections(type: SubjectType?) async {
    do {
      try await chii.loadUserCollections(type: type)
      try await chii.db.save()
    } catch {
      notifier.alert(error: error)
    }
  }

  var body: some View {
    if chii.isAuthenticated {
      NavigationStack(path: $navState.progressNavigation) {
        if counts.isEmpty {
          ProgressView().onAppear {
            Task {
              if loaded {
                return
              }
              loaded = true
              Logger.collection.info("initial loading progress")
              await load()
              await loadCounts()
            }
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
            .task {
              if counts.allSatisfy({ $0.value == 0 }) {
                await updateCollections(type: nil)
                await loadCounts()
                await load()
              }
            }
            ScrollView {
              LazyVStack(alignment: .leading, spacing: 10) {
                ForEach(collections, id: \.inner.self) { item in
                  NavigationLink(value: NavDestination.subject(subjectId: item.inner.subjectId)) {
                    ProgressRowView(subjectId: item.inner.subjectId)
                  }
                  .buttonStyle(.plain)
                  .onAppear {
                    Task {
                      await loadNextPage(idx: item.idx)
                    }
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
                await updateCollections(type: subjectType)
                await loadCounts()
                await load()
              }
            }
          }
          .animation(.default, value: counts)
          .animation(.default, value: collections)
          .padding(.horizontal, 8)
          .navigationDestination(for: NavDestination.self) { $0 }
        }
      }
    } else {
      AuthView(slogan: "使用 Bangumi 管理观看进度")
    }
  }
}
