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
  @State private var counts: [SubjectType: Int] = [:]

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

  func refresh(force: Bool = false) async {
    let now = Date()
    if force {
      collectionsUpdatedAt = 0
    }
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
    var loaded: [Int] = []
    while true {
      let resp = try await Chii.shared.getUserSubjectCollections(
        since: since, limit: limit, offset: offset)
      if resp.data.isEmpty {
        break
      }
      for item in resp.data {
        try await db.saveUserSubjectCollection(item)
        count += 1
        loaded.append(item.subject.id)
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
    if since > 0 {
      checkLoadEpisodes(loaded)
    }
    return count
  }

  func checkLoadEpisodes(_ subjectIds: [Int]) {
    Task.detached {
      for subjectId in subjectIds {
        do {
          try await Chii.shared.loadEpisodes(subjectId)
        } catch {
          await Notifier.shared.alert(error: error)
        }
      }
    }
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
              await loadCounts()
              refreshing = true
              await refresh()
              refreshing = false
              await loadCounts()
            }
          }
          .onChange(of: subjectType) {
            Task {
              await loadCounts()
            }
          }
          ChiiProgressListView(subjectType: subjectType, search: search)
            .padding(.horizontal, 8)
        }
        .searchable(text: $search)
        .animation(.default, value: subjectType)
        .animation(.default, value: counts)
        .refreshable {
          if refreshing {
            return
          }
          UIImpactFeedbackGenerator(style: .medium).impactOccurred()
          await refresh()
          await loadCounts()
        }
        .navigationTitle("进度管理")
        .toolbarTitleDisplayMode(.inlineLarge)
        .toolbar {
          ToolbarItem(placement: .topBarTrailing) {
            Menu {
              Button("刷新所有收藏", role: .destructive) {
                Task {
                  refreshing = true
                  await refresh(force: true)
                  refreshing = false
                  await loadCounts()
                }
              }
            } label: {
              Image(systemName: "ellipsis.circle")
            }
          }
        }
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
struct ChiiProgressListView: View {
  let subjectType: SubjectType
  let search: String

  @Environment(\.modelContext) var modelContext

  @Query var collections: [UserSubjectCollection]

  init(subjectType: SubjectType, search: String) {
    self.subjectType = subjectType
    self.search = search

    let stype = subjectType.rawValue
    let doingType = CollectionType.do.rawValue
    let descriptor = FetchDescriptor<UserSubjectCollection>(
      predicate: #Predicate<UserSubjectCollection> {
        (stype == 0 || $0.subjectType == stype) && $0.type == doingType
          && (search == "" || $0.alias.localizedStandardContains(search))
      },
      sortBy: [
        SortDescriptor(\.updatedAt, order: .reverse)
      ])
    self._collections = Query(descriptor)
  }

  var body: some View {
    LazyVStack(alignment: .leading) {
      ForEach(collections) { collection in
        CardView {
          ProgressRowView(subjectId: collection.subjectId).environment(collection)
        }
      }
    }.animation(.default, value: collections)
  }
}
