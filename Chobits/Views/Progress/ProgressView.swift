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
  @AppStorage("collectionsUpdatedAt") var collectionsUpdatedAt: Int = 0

  @Environment(\.modelContext) var modelContext

  @State private var refreshing: Bool = false
  @State private var refreshProgress: CGFloat = 0

  @FocusState private var searching: Bool
  @State private var search: String = ""
  @State private var subjectType: SubjectType = .none
  @State private var offset: Int = 0
  @State private var exhausted: Bool = false
  @State private var loadedIdx: [Int: Bool] = [:]
  @State private var counts: [SubjectType: Int] = [:]
  @State private var collections: [EnumerateItem<(UserSubjectCollection)>] = []

  func loadCounts() async {
    let doingType = CollectionType.do.rawValue
    do {
      for type in SubjectType.progressTypes {
        let tvalue = type.rawValue
        let desc: FetchDescriptor<UserSubjectCollection> = FetchDescriptor<UserSubjectCollection>(
          predicate: #Predicate<UserSubjectCollection> {
            (tvalue == 0 || $0.subjectType == tvalue) && $0.type == doingType
          })
        let count = try modelContext.fetchCount(desc)
        counts[type] = count
      }
    } catch {
      Notifier.shared.alert(error: error)
    }
  }

  func fetch(limit: Int = 20) async -> [EnumerateItem<UserSubjectCollection>] {
    let stype = subjectType.rawValue
    let doingType = CollectionType.do.rawValue
    var descriptor = FetchDescriptor<UserSubjectCollection>(
      predicate: #Predicate<UserSubjectCollection> {
        (stype == 0 || $0.subjectType == stype) && $0.type == doingType
          && (search == ""
            || ($0.subject?.name.localizedStandardContains(search) ?? false
              || $0.subject?.nameCN.localizedStandardContains(search) ?? false))
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
      Notifier.shared.alert(error: error)
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

  func refresh() async {
    let now = Date()
    do {
      let count = try await refreshCollections(since: collectionsUpdatedAt)
      if count > 0 {
        Notifier.shared.notify(message: "更新了 \(count) 条收藏")
      }
    } catch {
      Notifier.shared.alert(error: error)
    }
    collectionsUpdatedAt = Int(now.timeIntervalSince1970)
  }

  func refreshCollections(since: Int = 0) async throws -> Int {
    let db = try await Chii.shared.getDB()
    refreshProgress = 0
    let limit: Int = 100
    var offset: Int = 0
    var count: Int = 0
    while true {
      let resp = try await Chii.shared.getUserSubjectCollections(
        since: since, limit: limit, offset: offset)
      if resp.data.isEmpty {
        break
      }
      for item in resp.data {
        count += 1
        try await db.saveUserSubjectCollection(item)
        refreshProgress = CGFloat(count) / CGFloat(resp.total)
      }
      try await db.commit()
      await Chii.shared.index(resp.data.map { $0.subject.searchable() })
      offset += limit
      if offset >= resp.total {
        break
      }
    }
    try await db.commit()
    return count
  }

  var body: some View {
    VStack {
      if isAuthenticated {
        ScrollView {
          if refreshing {
            if collectionsUpdatedAt == 0 {
              HStack {
                ProgressView(value: refreshProgress)
              }
              .padding()
              .frame(height: 40)
            } else {
              HStack {
                Spacer()
                ProgressView()
                Spacer()
              }.frame(height: 40)
            }
          }
          Picker("Subject Type", selection: $subjectType) {
            ForEach(SubjectType.progressTypes) { type in
              Text("\(type.description)(\(counts[type, default: 0]))").tag(type)
            }
          }
          .padding(.horizontal, 8)
          .pickerStyle(.segmented)
          .onAppear {
            if !counts.isEmpty {
              return
            }
            Task {
              await load()
              refreshing = true
              await refresh()
              refreshing = false
              await load()
            }
          }
          .onChange(of: subjectType) {
            Task {
              await load()
            }
          }
          HStack {
            TextField("搜索", text: $search)
              .focused($searching)
              .textFieldStyle(.roundedBorder)
              .onChange(of: search) { _, _ in
                Task {
                  await load()
                }
              }
            Button {
              searching = false
              search = ""
            } label: {
              Image(systemName: "xmark.circle")
            }
            .disabled(!searching && search.isEmpty)
          }
          .padding(.horizontal, 8)
          .padding(.vertical, 2)
          LazyVStack(alignment: .leading) {
            ForEach(collections, id: \.inner) { item in
              CardView {
                ProgressRowView(collection: item.inner)
              }
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
        .animation(.default, value: subjectType)
        .animation(.default, value: counts)
        .animation(.default, value: collections)
        .refreshable {
          if refreshing {
            return
          }
          UIImpactFeedbackGenerator(style: .medium).impactOccurred()
          await refresh()
          await load()
        }
        .navigationTitle("进度管理")
        .toolbarTitleDisplayMode(.inlineLarge)
      } else {
        AuthView(slogan: "使用 Bangumi 管理观看进度")
          .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
              NavigationLink(value: NavDestination.setting) {
                Image(systemName: "gearshape")
              }
            }
          }
      }
    }
  }
}
