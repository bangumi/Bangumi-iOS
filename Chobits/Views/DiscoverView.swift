//
//  DiscoverView.swift
//  Chobits
//
//  Created by Chuan Chuan on 2024/4/19.
//

import SwiftData
import SwiftUI

struct ChiiDiscoverView: View {
  @EnvironmentObject var notifier: Notifier
  @EnvironmentObject var chii: ChiiClient
  @EnvironmentObject var navState: NavState
  @Environment(\.modelContext) private var modelContext

  @State private var searching = false
  @State private var query = ""
  @State private var subjectType: SubjectType = .unknown
  @State private var local = true
  @State private var offset = 0
  @State private var exhausted = false

  @State private var subjects: [EnumerateItem<Subject>] = []

  func localSearch(limit: Int = 50) async -> [EnumerateItem<Subject>] {
    let actor = BackgroundActor(container: modelContext.container)
    let predicate = #Predicate<Subject> {
      return (subjectType.rawValue == 0 || subjectType.rawValue == $0.type)
        && ($0.name.localizedStandardContains(query)
          || $0.nameCn.localizedStandardContains(query))
    }
    do {
      let subjects = try await actor.fetchData(
        predicate: predicate, limit: limit, offset: offset)
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
    local = true
    offset = 0
    exhausted = false
    subjects.removeAll()
    let subjects = await localSearch()
    self.subjects.append(contentsOf: subjects)
  }

  func localSearchNextPage(idx: Int) async {
    if exhausted {
      return
    }
    if idx != subjects.count - 10 {
      return
    }
    let subjects = await localSearch()
    self.subjects.append(contentsOf: subjects)
  }

  func remoteSearch(limit: Int = 50) async -> [EnumerateItem<Subject>] {
    let actor = BackgroundActor(container: modelContext.container)
    do {
      let resp = try await chii.search(
        keyword: query, type: subjectType, limit: limit, offset: offset)
      offset += limit
      if offset > resp.total {
        exhausted = true
      }
      var result: [EnumerateItem<Subject>] = []
      for item in resp.data.enumerated() {
        let subject = Subject(search: item.element)
        let subjectId = item.element.id
        try await actor.insertIfNeeded(
          data: subject,
          predicate: #Predicate<Subject> {
            $0.id == subjectId
          })
        result.append(EnumerateItem(idx: item.offset, inner: subject))
      }
      try await actor.save()
      if result.count < limit {
        exhausted = true
      }
      return result
    } catch {
      notifier.alert(error: error)
    }
    return []
  }

  func newRemoteSearch() async {
    local = false
    offset = 0
    exhausted = false
    subjects.removeAll()
    let subjects = await remoteSearch()
    self.subjects.append(contentsOf: subjects)
  }

  func remoteSearchNextPage(idx: Int) async {
    if exhausted {
      return
    }
    if idx != subjects.count - 10 {
      return
    }
    let subjects = await remoteSearch()
    self.subjects.append(contentsOf: subjects)
  }

  var body: some View {
    NavigationStack(path: $navState.discoverNavigation) {
      Section {
        if searching {
          Picker("Subject Type", selection: $subjectType) {
            Text("全部").tag(SubjectType.unknown)
            ForEach(SubjectType.searchTypes()) { type in
              Text(type.description).tag(type)
            }
          }
          .onChange(of: subjectType) { _, _ in
            if query.isEmpty {
              return
            }
            Task(priority: .background) {
              if local {
                await newLocalSearch()
              } else {
                await newRemoteSearch()
              }
            }
          }
          .pickerStyle(.segmented)
          .padding(.horizontal, 16)
          if !query.isEmpty {
            if subjects.isEmpty && !local {
              VStack {
                Spacer()
                ProgressView()
                Spacer()
              }
            } else {
              ScrollView {
                LazyVStack(alignment: .leading, spacing: 10) {
                  ForEach(subjects, id: \.idx) { item in
                    NavigationLink(value: NavDestination.subject(subjectId: item.inner.id)) {
                      SubjectSearchRow(subject: item.inner)
                        .task(priority: .background) {
                          if local {
                            await localSearchNextPage(idx: item.idx)
                          } else {
                            await remoteSearchNextPage(idx: item.idx)
                          }
                        }
                    }.buttonStyle(PlainButtonStyle())
                  }
                }
              }
              .animation(.easeInOut, value: subjectType)
              .navigationBarTitleDisplayMode(.inline)
              .padding(.horizontal, 16)
            }
          }
          Spacer()
        } else {
          CalendarView()
            .navigationBarTitleDisplayMode(.inline)
            .padding(.horizontal, 16)
        }
      }
      .navigationDestination(for: NavDestination.self) { nav in
        switch nav {
        case .subject(let sid):
          SubjectView(subjectId: sid)
        case .episodeList(let sid):
          EpisodeListView(subjectId: sid)
        }
      }
    }
    .searchable(text: $query, isPresented: $searching)
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
