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

  @State private var subjectType: SubjectType = .none
  @State private var refreshing: Bool = false
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
        let desc = FetchDescriptor<UserSubjectCollection>(
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
      let count = try await Chii.shared.loadUserSubjectCollections(
        since: collectionsUpdatedAt)
      if count > 0 {
        Notifier.shared.notify(message: "更新了 \(count) 条收藏")
      }
    } catch {
      Notifier.shared.alert(error: error)
    }
    collectionsUpdatedAt = Int(now.timeIntervalSince1970)
  }

  var body: some View {
    VStack {
      if isAuthenticated {
        ScrollView {
          if refreshing {
            HStack {
              Spacer()
              ProgressView()
              Spacer()
            }.frame(height: 40)
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
          LazyVStack(alignment: .leading) {
            ForEach(collections, id: \.idx) { item in
              CardView {
                NavigationLink(value: NavDestination.subject(subjectId: item.inner.subjectId)) {
                  ProgressRowView(collection: item.inner)
                }.buttonStyle(.plain)
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
