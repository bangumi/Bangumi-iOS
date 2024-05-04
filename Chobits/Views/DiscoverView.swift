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

  @State private var subjects: [SearchSubject] = []
  @State private var collections: [UserSubjectCollection] = []

  func localSearch(limit: Int = 20) async -> [UserSubjectCollection] {
    let actor = BackgroundActor(container: modelContext.container)
    let predicate = #Predicate<UserSubjectCollection> {
      return (subjectType.rawValue == 0 || subjectType.rawValue == $0.subjectType)
        && ($0.subject.name.localizedStandardContains(query)
          || $0.subject.nameCn.localizedStandardContains(query))
    }
    do {
      let collections = try await actor.fetchData(
        predicate: predicate, limit: limit, offset: offset)
      if collections.count < limit {
        exhausted = true
      }
      offset += limit
      return collections
    } catch {
      notifier.alert(error: error)
    }
    return []
  }

  func newLocalSearch() async {
    local = true
    offset = 0
    exhausted = false
    collections.removeAll()
    let collections = await localSearch()
    self.collections.append(contentsOf: collections)
  }

  func localSearchNextPage(current: UserSubjectCollection) async {
    if exhausted {
      return
    }
    let thresholdIndex = collections.index(collections.endIndex, offsetBy: -2)
    let currentIndex = collections.firstIndex(where: { $0.id == current.id })
    if currentIndex != thresholdIndex {
      return
    }
    let collections = await localSearch()
    self.collections.append(contentsOf: collections)
  }

  func remoteSearch(limit: Int = 20) async -> [SearchSubject] {
    do {
      let resp = try await chii.search(
        keyword: query, type: subjectType, limit: limit, offset: offset)
      offset += limit
      if offset > resp.total {
        exhausted = true
      }
      return resp.data
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

  func remoteSearchNextPage(current: SearchSubject) async {
    if exhausted {
      return
    }
    let thresholdIndex = subjects.index(subjects.endIndex, offsetBy: -2)
    let currentIndex = subjects.firstIndex(where: { $0.id == current.id })
    if currentIndex != thresholdIndex {
      return
    }
    let subjects = await remoteSearch()
    self.subjects.append(contentsOf: subjects)
  }

  var body: some View {
    NavigationStack(path: $navState.discoverNavigation) {
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
          Task {
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
          if local {
            ScrollView {
              LazyVStack(alignment: .leading, spacing: 10) {
                ForEach(collections) { collection in
                  NavigationLink(value: collection) {
                    SubjectSearchLocalRow(collection: collection).task {
                      await localSearchNextPage(current: collection)
                    }
                  }.buttonStyle(PlainButtonStyle())
                }
              }
            }
            .animation(.easeInOut, value: subjectType)
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(for: UserSubjectCollection.self) { collection in
              SubjectView(subjectId: collection.subjectId)
            }
            .padding(.horizontal, 16)
          } else {
            if subjects.isEmpty {
              VStack {
                Spacer()
                ProgressView()
                Spacer()
              }
            } else {
              ScrollView {
                LazyVStack(alignment: .leading, spacing: 10) {
                  ForEach(subjects) { subject in
                    NavigationLink(value: subject) {
                      SubjectSearchRemoteRow(subject: subject).task {
                        await remoteSearchNextPage(current: subject)
                      }
                    }.buttonStyle(PlainButtonStyle())
                  }
                }
              }
              .animation(.easeInOut, value: subjectType)
              .navigationBarTitleDisplayMode(.inline)
              .navigationDestination(for: SearchSubject.self) { subject in
                SubjectView(subjectId: subject.id)
              }
              .padding(.horizontal, 16)
            }
          }
        }
        Spacer()
      } else {
        CalendarView()
          .navigationBarTitleDisplayMode(.inline)
          .navigationDestination(for: SmallSubject.self) { subject in
            SubjectView(subjectId: subject.id)
          }
          .padding(.horizontal, 16)
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
