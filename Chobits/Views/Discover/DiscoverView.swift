//
//  DiscoverView.swift
//  Chobits
//
//  Created by Chuan Chuan on 2024/4/19.
//

import OSLog
import SwiftData
import SwiftUI

struct ChiiDiscoverView: View {
  @Environment(Notifier.self) private var notifier
  @Environment(\.modelContext) var modelContext

  @State private var searching = false
  @State private var query = ""
  @State private var subjectType: SubjectType = .unknown
  @State private var local = true
  @State private var offset = 0
  @State private var exhausted = false

  @State private var loadedIdx: [Int: Bool] = [:]
  @State private var subjects: [EnumerateItem<Subject>] = []

  func localSearch(limit: Int = 50) async -> [EnumerateItem<Subject>] {
    var desc = FetchDescriptor<Subject>(
      predicate: #Predicate<Subject> {
        return (subjectType.rawValue == 0 || subjectType.rawValue == $0.type)
          && ($0.name.localizedStandardContains(query)
            || $0.nameCn.localizedStandardContains(query))
      })
    desc.fetchLimit = limit
    desc.fetchOffset = offset
    do {
      let subjects = try modelContext.fetch(desc)
      if subjects.count < limit {
        exhausted = true
      }
      let result = subjects.enumerated().map { (idx, subject) in
        EnumerateItem(idx: idx + offset, inner: subject)
      }
      offset += limit
      return result
    } catch {
      notifier.alert(error: error)
    }
    return []
  }

  func newLocalSearch() async {
    Logger.app.info("new local search")
    local = true
    offset = 0
    exhausted = false
    loadedIdx.removeAll()
    subjects.removeAll()
    let subjects = await localSearch()
    self.subjects.append(contentsOf: subjects)
  }

  func localSearchNextPage(idx: Int) async {
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
    let subjects = await localSearch()
    self.subjects.append(contentsOf: subjects)
  }

  func remoteSearch(limit: Int = 50) async -> [EnumerateItem<Subject>] {
    do {
      guard let db = await Chii.shared.db else {
        throw ChiiError.uninitialized
      }
      let resp = try await Chii.shared.search(
        keyword: query, type: subjectType, limit: limit, offset: offset)
      if offset > resp.total {
        Logger.app.info("remote search exhausted at total count: \(resp.total)")
        exhausted = true
      }
      var result: [EnumerateItem<Subject>] = []
      for item in resp.data.enumerated() {
        try await db.saveSubject(item.element)
        result.append(EnumerateItem(idx: item.offset + offset, inner: Subject(item.element)))
      }
      try await db.commit()
      if result.count < limit {
        exhausted = true
      }
      offset += limit
      return result
    } catch {
      notifier.alert(error: error)
    }
    return []
  }

  func newRemoteSearch() async {
    Logger.app.info("new remote search")
    local = false
    offset = 0
    exhausted = false
    loadedIdx.removeAll()
    subjects.removeAll()
    let subjects = await remoteSearch()
    self.subjects.append(contentsOf: subjects)
  }

  func remoteSearchNextPage(idx: Int) async {
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
    let subjects = await remoteSearch()
    self.subjects.append(contentsOf: subjects)
  }

  var body: some View {
    NavigationStack {
      VStack {
        if searching {
          Picker("Subject Type", selection: $subjectType) {
            Text("全部").tag(SubjectType.unknown)
            ForEach(SubjectType.allTypes()) { type in
              Text(type.description).tag(type)
            }
          }
          .onChange(of: subjectType) { _, _ in
            if query.isEmpty {
              return
            }
            Task {
              if local {
                await newLocalSearch()
              } else {
                await newRemoteSearch()
              }
            }
          }
          .pickerStyle(.segmented)
          .padding(.horizontal, 8)
          if !query.isEmpty {
            if subjects.isEmpty && !local && !exhausted {
              VStack {
                Spacer()
                ProgressView()
                Spacer()
              }
            } else {
              ScrollView {
                LazyVStack(alignment: .leading, spacing: 10) {
                  ForEach(subjects, id: \.inner.self) { item in
                    NavigationLink(value: NavDestination.subject(subjectId: item.inner.subjectId)) {
                      SubjectLargeRowView(subjectId: item.inner.subjectId)
                        .onAppear {
                          Task {
                            if local {
                              await localSearchNextPage(idx: item.idx)
                            } else {
                              await remoteSearchNextPage(idx: item.idx)
                            }
                          }
                        }
                    }.buttonStyle(.plain)
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
                }.padding(.horizontal, 8)
              }.animation(.easeInOut, value: subjectType)
            }
          }
          Spacer()
        } else {
          CalendarView()
        }
      }
      .navigationDestination(for: NavDestination.self) { $0 }
      .navigationTitle("发现")
      .toolbarTitleDisplayMode(.inlineLarge)
    }
    .searchable(
      text: $query, isPresented: $searching, placement: .navigationBarDrawer(displayMode: .always)
    )
    .onChange(of: query) { _, _ in
      Task {
        await newLocalSearch()
      }
    }
    .onSubmit(of: .search) {
      Task {
        await newRemoteSearch()
      }
    }
    .onOpenURL(perform: { url in
      // TODO: handle urls
      print(url)
    })
  }
}
