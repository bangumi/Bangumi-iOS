//
//  SubjectTopicListView.swift
//  Chobits
//
//  Created by Chuan Chuan on 2024/10/5.
//

import OSLog
import SwiftData
import SwiftUI

struct SubjectTopicListView: View {
  let subjectId: Int

  @State private var fetching: Bool = false
  @State private var offset: Int = 0
  @State private var exhausted: Bool = false
  @State private var loadedIdx: [Int: Bool] = [:]
  @State private var topics: [EnumerateItem<TopicDTO>] = []

  func fetch(limit: Int = 20) async -> [EnumerateItem<TopicDTO>] {
    fetching = true
    do {
      let resp = try await Chii.shared.getSubjectTopics(subjectId, limit: limit, offset: offset)
      if resp.total < offset + limit {
        exhausted = true
      }
      let result = resp.data.enumerated().map { (idx, item) in
        EnumerateItem(idx: idx + offset, inner: item)
      }
      offset += limit
      fetching = false
      return result
    } catch {
      Notifier.shared.alert(error: error)
    }
    fetching = false
    return []
  }

  func load() async {
    offset = 0
    exhausted = false
    loadedIdx.removeAll()
    topics.removeAll()
    let items = await fetch()
    self.topics.append(contentsOf: items)
  }

  func loadNextPage(idx: Int) async {
    if exhausted {
      return
    }
    if idx != offset - 5 {
      return
    }
    if loadedIdx[idx, default: false] {
      return
    }
    loadedIdx[idx] = true
    let items = await fetch()
    self.topics.append(contentsOf: items)
  }

  var body: some View {
    ScrollView {
      LazyVStack(alignment: .leading) {
        ForEach(topics, id: \.inner.self) { item in
          let topic = item.inner
          VStack {
            HStack {
              NavigationLink(value: NavDestination.topic(topic)) {
                Text("\(topic.title)")
                  .font(.callout)
                  .lineLimit(1)
              }
              Spacer()
              if topic.repliesCount > 0 {
                Text("(+\(topic.repliesCount))")
                  .font(.footnote)
                  .foregroundStyle(.secondary)
              }
            }
            HStack {
              Text(topic.createdAt.dateDisplay)
                .lineLimit(1)
                .foregroundStyle(.secondary)
              Spacer()
              NavigationLink(value: NavDestination.user(topic.creator.uid)) {
                Text(topic.creator.nickname)
                  .lineLimit(1)
              }
            }.font(.footnote)
            Divider()
          }
          .padding(.top, 2)
          .onAppear {
            Task {
              await loadNextPage(idx: item.idx)
            }
          }
        }
        if fetching {
          HStack {
            Spacer()
            ProgressView()
            Spacer()
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
    .buttonStyle(.navLink)
    .animation(.default, value: topics)
    .navigationTitle("讨论版")
    .navigationBarTitleDisplayMode(.inline)
    .toolbar {
      ToolbarItem(placement: .automatic) {
        Image(systemName: "list.bullet.circle").foregroundStyle(.secondary)
      }
    }
    .onAppear {
      if topics.count > 0 {
        return
      }
      Task {
        await load()
      }
    }
  }
}

#Preview {
  let container = mockContainer()

  let subject = Subject.previewAnime
  container.mainContext.insert(subject)

  return ScrollView {
    LazyVStack(alignment: .leading) {
      SubjectTopicListView(subjectId: subject.subjectId)
        .modelContainer(container)
    }
  }.padding()
}
