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
  @AppStorage("isAuthenticated") var isAuthenticated: Bool = false

  @Environment(Notifier.self) private var notifier
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
    do {
      for type in SubjectType.progressTypes() {
        if type == .unknown {
          continue
        }
        let tvalue = type.rawValue
        let desc = FetchDescriptor<UserSubjectCollection>(
          predicate: #Predicate<UserSubjectCollection> {
            $0.type == doingType && $0.subjectType == tvalue
          })
        let count = try modelContext.fetchCount(desc)
        counts[type] = count
      }
      let desc = FetchDescriptor<UserSubjectCollection>(
        predicate: #Predicate<UserSubjectCollection> {
          $0.type == doingType
        })
      let totalCount = try modelContext.fetchCount(desc)
      Logger.collection.info("load progress total count: \(totalCount)")
      counts[.unknown] = totalCount
    } catch {
      notifier.alert(error: error)
    }
  }

  func fetch(limit: Int = 20) async -> [EnumerateItem<UserSubjectCollection>] {
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
      let collections = try modelContext.fetch(descriptor)
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
    await loadCounts()
    let collections = await fetch()
    self.collections.append(contentsOf: collections)
  }

  func loadNextPage(idx: Int) async {
    if exhausted {
      return
    }
    if idx != offset - 3 {
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
      try await Chii.shared.loadUserCollections(type: type)
    } catch {
      notifier.alert(error: error)
    }
  }

  var body: some View {
    NavigationStack {
      VStack {
        if isAuthenticated {
          if counts.isEmpty {
            ProgressView().onAppear {
              Task {
                if loaded {
                  return
                }
                loaded = true
                Logger.collection.info("initial loading progress")
                await load()
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
                    Divider()
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
                  await load()
                }
              }
            }
            .animation(.default, value: counts)
            .animation(.default, value: collections)
            .padding(.horizontal, 8)
          }
        } else {
          AuthView(slogan: "使用 Bangumi 管理观看进度")
        }
      }
      .navigationDestination(for: NavDestination.self) { $0 }
    }
  }
}
