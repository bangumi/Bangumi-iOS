//
//  DiscoverView.swift
//  Chobits
//
//  Created by Chuan Chuan on 2024/4/19.
//

import SwiftData
import SwiftUI

struct ChiiDiscoverView: View {
  @EnvironmentObject var errorHandling: ErrorHandling
  @EnvironmentObject var chiiClient: ChiiClient
  @EnvironmentObject var navState: NavState

  @State private var searching = false
  @State private var query = ""
  @State private var local = true
  @State private var subjectType: SubjectType = .unknown

  @State private var limit: UInt = 20
  @State private var offset: UInt = 0
  @State private var total: UInt = 0
  @State private var subjects: [SearchSubject] = []

  @Query private var collections: [UserSubjectCollection]

  var filteredCollections: [UserSubjectCollection] {
    if !local || query.isEmpty {
      return []
    }
    let filtered = collections.filter {
      if let subject = $0.subject {
        if subjectType != .unknown && subjectType != subject.type {
          return false
        }
        return subject.nameCn.lowercased().contains(query) || subject.name.lowercased().contains(query)
      } else {
        return false
      }
    }
    return Array(filtered.prefix(10))
  }

  func newSearch() {
    offset = 0
    total = 0
    local = false
    subjects = []
    Task.detached {
      let resp = try await chiiClient.search(
        keyword: query, type: subjectType, offset: offset, limit: limit)
      await MainActor.run {
        withAnimation {
          total = resp.total
          subjects = resp.data
        }
      }
    }
  }

  func checkSearchNextPage(current: SearchSubject) {
    if offset + limit > total {
      return
    }
    let thresholdIndex = subjects.index(subjects.endIndex, offsetBy: -2)
    let currentIndex = subjects.firstIndex(where: { $0.id == current.id })
    if currentIndex != thresholdIndex {
      return
    }
    offset += limit
    Task.detached {
      let resp = try await chiiClient.search(
        keyword: query, type: subjectType, offset: offset, limit: limit)
      await MainActor.run {
        withAnimation {
          subjects.append(contentsOf: resp.data)
        }
      }
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
          if local {
            return
          }
          if query.isEmpty {
            return
          }
          offset = 0
          newSearch()
        }
        .pickerStyle(.segmented)
        .padding(.horizontal, 16)
        if query.isEmpty {
          EmptyView()
        } else {
          if local {
            ScrollView {
              LazyVStack(alignment: .leading, spacing: 10) {
                ForEach(filteredCollections) { collection in
                  NavigationLink(value: collection) {
                    SubjectSearchLocalRow(collection: collection)
                  }.buttonStyle(PlainButtonStyle())
                }
              }
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(for: UserSubjectCollection.self) { collection in
              SubjectView(sid: collection.subjectId)
            }
            .padding(.horizontal, 16)
          } else {
            if subjects.isEmpty {
              ProgressView()
            } else {
              ScrollView {
                LazyVStack(alignment: .leading, spacing: 10) {
                  ForEach(subjects) { subject in
                    NavigationLink(value: subject) {
                      SubjectSearchRemoteRow(subject: subject).onAppear {
                        checkSearchNextPage(current: subject)
                      }
                    }.buttonStyle(PlainButtonStyle())
                  }
                }
              }
              .navigationBarTitleDisplayMode(.inline)
              .navigationDestination(for: SearchSubject.self) { subject in
                SubjectView(sid: subject.id)
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
            SubjectView(sid: subject.id)
          }
          .padding(.horizontal, 16)
      }
    }
    .searchable(text: $query, isPresented: $searching)
    .onChange(of: query) { _, _ in
      local = true
      subjects = []
    }
    .onSubmit(of: .search, newSearch)
    .onOpenURL(perform: { url in
      // TODO: handle urls
      print(url)
    })
  }
}
