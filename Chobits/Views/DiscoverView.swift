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
  @State private var local = true
  @State private var subjectType: SubjectType = .unknown

  @State private var limit: Int = 20
  @State private var offset: Int = 0
  @State private var total: Int = 0
  @State private var subjects: [SearchSubject] = []
  @State private var collections: [UserSubjectCollection] = []

  func newLocalSearch() async {
    offset = 0
    total = 0
    local = true
    subjects = []
    let actor = BackgroundActor(container: modelContext.container)
    let stype = subjectType.rawValue
    let allType = SubjectType.unknown.rawValue
    let predicate = #Predicate<UserSubjectCollection> {
      return (stype == allType || stype == $0.subjectType)
        && ($0.subject.name.localizedStandardContains(query)
          || $0.subject.nameCn.localizedStandardContains(query))
    }
    do {
      let collections = try await actor.fetchData(
        predicate: predicate, limit: limit, offset: offset)
      if collections.count < limit {
        total = -1
      }
      self.collections = collections
    } catch {
      notifier.alert(message: "\(error)")
    }
  }

  func localSearchNextPage(current: UserSubjectCollection) async {
    if total < 0 {
      return
    }
    let thresholdIndex = collections.index(collections.endIndex, offsetBy: -2)
    let currentIndex = collections.firstIndex(where: { $0.id == current.id })
    if currentIndex != thresholdIndex {
      return
    }
    offset += limit
    let actor = BackgroundActor(container: modelContext.container)
    let predicate = #Predicate<UserSubjectCollection> {
      return $0.subject.name.localizedStandardContains(query)
        || $0.subject.nameCn.localizedStandardContains(query)
    }
    do {
      let collections = try await actor.fetchData(
        predicate: predicate, limit: limit, offset: offset)
      if collections.count < limit {
        total = -1
      }
      self.collections.append(contentsOf: collections)
    } catch {
      notifier.alert(message: "\(error)")
    }
  }

  func newRemoteSearch() async {
    offset = 0
    total = 0
    local = false
    subjects = []
    do {
      let resp = try await chii.search(
        keyword: query, type: subjectType, limit: limit, offset: offset)
      total = resp.total
      subjects = resp.data
    } catch {
      notifier.alert(message: "\(error)")
    }
  }

  func remoteSearchNextPage(current: SearchSubject) async {
    if offset + limit > total {
      return
    }
    let thresholdIndex = subjects.index(subjects.endIndex, offsetBy: -2)
    let currentIndex = subjects.firstIndex(where: { $0.id == current.id })
    if currentIndex != thresholdIndex {
      return
    }
    offset += limit
    do {
      let resp = try await chii.search(
        keyword: query, type: subjectType, limit: limit, offset: offset)
      subjects.append(contentsOf: resp.data)
    } catch {
      notifier.alert(message: "\(error)")
    }
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
