//
//  DiscoverView.swift
//  Chobits
//
//  Created by Chuan Chuan on 2024/4/19.
//

import OSLog
import SwiftData
import SwiftUI

struct SearchView: View {
  @Binding var text: String
  @Binding var remote: Bool

  @Environment(\.modelContext) var modelContext

  @State private var subjectType: SubjectType = .none
  @State private var offset = 0
  @State private var exhausted = false

  @State private var loadedIdx: [Int: Bool] = [:]
  @State private var subjects: [EnumerateItem<Subject>] = []

  func localSearch(limit: Int = 10) async -> [EnumerateItem<Subject>] {
    var desc = FetchDescriptor<Subject>(
      predicate: #Predicate<Subject> {
        return (subjectType.rawValue == 0 || subjectType.rawValue == $0.type)
          && ($0.name.localizedStandardContains(text)
            || $0.nameCN.localizedStandardContains(text))
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
      Notifier.shared.alert(error: error)
    }
    return []
  }

  func remoteSearch(limit: Int = 10) async -> [EnumerateItem<Subject>] {
    do {
      guard let db = await Chii.shared.db else {
        throw ChiiError.uninitialized
      }
      let resp = try await Chii.shared.search(
        keyword: text, type: subjectType, limit: limit, offset: offset)
      if offset > resp.total {
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
      Notifier.shared.alert(error: error)
    }
    return []
  }

  func newSearch() {
    offset = 0
    exhausted = false
    loadedIdx.removeAll()
    subjects.removeAll()
    if text.isEmpty {
      return
    }
    Task {
      if remote {
        let subjects = await remoteSearch()
        self.subjects.append(contentsOf: subjects)
      } else {
        let subjects = await localSearch()
        self.subjects.append(contentsOf: subjects)
      }
    }
  }

  func searchNextPage(idx: Int) async {
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
    if remote {
      let subjects = await remoteSearch()
      self.subjects.append(contentsOf: subjects)
    } else {
      let subjects = await localSearch()
      self.subjects.append(contentsOf: subjects)
    }
  }

  var body: some View {
    ScrollView {
      VStack {
        HStack {
          Picker("Subject Type", selection: $subjectType) {
            Text("全部").tag(SubjectType.none)
            ForEach(SubjectType.allTypes) { type in
              Text(type.description).tag(type)
            }
          }
          .pickerStyle(.segmented)
          .onChange(of: subjectType) {
            newSearch()
          }
          .onChange(of: $text.wrappedValue) {
            newSearch()
          }
          .onChange(of: $remote.wrappedValue) {
            newSearch()
          }
        }
      }.padding(8)
      if text.isEmpty {
        Text("输入关键字搜索")
          .foregroundStyle(.secondary)
          .padding(8)
      } else {
        if subjects.isEmpty && remote && !exhausted {
          VStack {
            Spacer()
            ProgressView()
            Spacer()
          }.padding(8)
        } else {
          LazyVStack(alignment: .leading) {
            ForEach(subjects, id: \.inner.self) { item in
              CardView {
                SubjectLargeRowView(subjectId: item.inner.subjectId)
              }
              .onAppear {
                Task {
                  await searchNextPage(idx: item.idx)
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
          }
          .padding(.horizontal, 8)
          .animation(.default, value: subjects)
        }
      }
    }
  }
}
