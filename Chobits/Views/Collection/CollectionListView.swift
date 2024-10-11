//
//  CollectionListView.swift
//  Chobits
//
//  Created by Chuan Chuan on 2024/5/15.
//

import SwiftData
import SwiftUI

struct CollectionListView: View {
  let subjectType: SubjectType

  @Environment(Notifier.self) private var notifier
  @Environment(\.modelContext) var modelContext

  @State private var loaded: Bool = false
  @State private var collectionType = CollectionType.collect
  @State private var offset: Int = 0
  @State private var exhausted: Bool = false
  @State private var loadedIdx: [Int: Bool] = [:]
  @State private var counts: [CollectionType: Int] = [:]
  @State private var collections: [EnumerateItem<(UserSubjectCollection)>] = []

  func loadCounts() async {
    let stype = subjectType.rawValue
    do {
      for type in CollectionType.allTypes() {
        let ctype = type.rawValue
        let desc = FetchDescriptor<UserSubjectCollection>(
          predicate: #Predicate<UserSubjectCollection> {
            $0.type == ctype && $0.subjectType == stype
          })
        let count = try modelContext.fetchCount(desc)
        counts[type] = count
      }
    } catch {
      notifier.alert(error: error)
    }
  }

  func fetch(limit: Int = 20) async -> [EnumerateItem<UserSubjectCollection>] {
    let stype = subjectType.rawValue
    let ctype = collectionType.rawValue
    var descriptor = FetchDescriptor<UserSubjectCollection>(
      predicate: #Predicate<UserSubjectCollection> {
        $0.subjectType == stype && $0.type == ctype
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

  var body: some View {
    Section {
      if counts.isEmpty {
        ProgressView().onAppear {
          Task {
            if loaded {
              return
            }
            loaded = true
            await load()
            await loadCounts()
          }
        }
      } else {
        VStack {
          Picker("Collection Type", selection: $collectionType) {
            ForEach(CollectionType.allTypes()) { ctype in
              Text("\(ctype.description(type: subjectType))(\(counts[ctype, default: 0]))").tag(
                ctype)
            }
          }
          .pickerStyle(.segmented)
          .onChange(of: collectionType) {
            Task {
              await load()
            }
          }
          ScrollView {
            LazyVStack(alignment: .leading, spacing: 10) {
              ForEach(collections, id: \.inner.self) { item in
                NavigationLink(value: NavDestination.subject(subjectId: item.inner.subjectId)) {
                  CollectionRowView(subjectId: item.inner.subjectId)
                }
                .buttonStyle(.plain)
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
          .animation(.easeInOut, value: collectionType)
        }
        .animation(.default, value: counts)
        .animation(.default, value: collections)
      }
    }
    .navigationTitle("我的\(subjectType.description)")
    .navigationBarTitleDisplayMode(.inline)
  }
}

#Preview {
  let container = mockContainer()

  let collection = UserSubjectCollection.previewAnime
  let subject = Subject.previewAnime
  container.mainContext.insert(subject)
  container.mainContext.insert(collection)

  return CollectionListView(subjectType: SubjectType.anime)
    .environment(Notifier())
    .modelContainer(container)
}
