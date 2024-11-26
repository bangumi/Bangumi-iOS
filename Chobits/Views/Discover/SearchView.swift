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
  @Environment(\.modelContext) var modelContext

  @FocusState private var searching: Bool
  @State private var text: String = ""
  @State private var remote: Bool = false

  @State private var subjectType: SubjectType = .unknown
  @State private var offset = 0
  @State private var exhausted = false

  @State private var loadedIdx: [Int: Bool] = [:]
  @State private var subjects: [EnumerateItem<Subject>] = []

  func localSearch(limit: Int = 10) async -> [EnumerateItem<Subject>] {
    var desc = FetchDescriptor<Subject>(
      predicate: #Predicate<Subject> {
        return (subjectType.rawValue == 0 || subjectType.rawValue == $0.type)
          && ($0.name.localizedStandardContains(text)
            || $0.nameCn.localizedStandardContains(text))
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
      Notifier.shared.alert(error: error)
    }
    return []
  }

  func newSearch() async {
    offset = 0
    exhausted = false
    loadedIdx.removeAll()
    subjects.removeAll()
    if text.isEmpty {
      return
    }
    if remote {
      Logger.app.info("new remote search")
      let subjects = await remoteSearch()
      self.subjects.append(contentsOf: subjects)
    } else {
      Logger.app.info("new local search")
      let subjects = await localSearch()
      self.subjects.append(contentsOf: subjects)
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
    VStack {
      VStack {
        HStack {
          Picker("Subject Type", selection: $subjectType) {
            Text("全部").tag(SubjectType.unknown)
            ForEach(SubjectType.allTypes) { type in
              Text(type.description).tag(type)
            }
          }
          .pickerStyle(.menu)
          .onChange(of: subjectType) { _, _ in
            Task {
              await newSearch()
            }
          }
          TextField("搜索", text: $text)
            .focused($searching)
            .textFieldStyle(.roundedBorder)
            .onAppear {
              if text.isEmpty {
                searching = true
              }
            }
            .onChange(of: text) { _, _ in
              remote = false
              Task {
                await newSearch()
              }
            }
            .onSubmit {
              remote = true
              Task {
                await newSearch()
              }
            }
          Button {
            searching = false
            remote = false
            text = ""
          } label: {
            Image(systemName: "xmark.circle")
          }
          .disabled(!searching && text.isEmpty)
        }
      }.padding(.horizontal, 8)
      if text.isEmpty {
        Text("输入关键字搜索").foregroundStyle(.secondary)
      } else {
        if subjects.isEmpty && remote && !exhausted {
          VStack {
            Spacer()
            ProgressView()
            Spacer()
          }
        } else {
          ScrollView {
            LazyVStack(alignment: .leading) {
              ForEach(subjects, id: \.inner.self) { item in
                NavigationLink(value: NavDestination.subject(subjectId: item.inner.subjectId)) {
                  SubjectLargeRowView(subjectId: item.inner.subjectId).padding(8)
                }
                .background(Color("CardBackgroundColor"))
                .cornerRadius(8)
                .shadow(color: Color.black.opacity(0.2), radius: 4)
                .buttonStyle(.plain)
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
            }.padding(8)
          }
          .animation(.default, value: subjects)
        }
      }
      Spacer()
    }
  }
}
