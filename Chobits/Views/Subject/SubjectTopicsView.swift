//
//  SubjectTopicsView.swift
//  Chobits
//
//  Created by Chuan Chuan on 2024/10/5.
//

import SwiftData
import SwiftUI

struct SubjectTopicsView: View {
  let subjectId: UInt

  @Environment(Notifier.self) private var notifier

  @State private var refreshing: Bool = false
  @State private var topics: [Topic] = []

  func refresh() async {
    if topics.count > 0 {
      return
    }
    refreshing = true
    do {
      let resp = try await Chii.shared.getSubjectTopics(subjectId: subjectId, limit: 5)
      topics = resp.data
    } catch {
      notifier.alert(error: error)
    }
    refreshing = false
  }

  var body: some View {
    Divider()
    HStack {
      Text("讨论版")
        .foregroundStyle(topics.count > 0 ? .primary : .secondary)
        .font(.title3)
        .task {
          await refresh()
        }
      if refreshing {
        ProgressView()
      }
      Spacer()
      if topics.count > 0 {
        NavigationLink(value: NavDestination.subjectTopicList(subjectId: subjectId)) {
          Text("更多讨论 »").font(.caption).foregroundStyle(.linkText)
        }.buttonStyle(.plain)
      }
    }
    VStack {
      ForEach(topics) { topic in
        VStack {
          HStack {
            NavigationLink(value: NavDestination.topic(topic: topic)) {
              Text("\(topic.title)")
                .lineLimit(1)
                .foregroundStyle(.linkText)
            }.buttonStyle(.plain)
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
            NavigationLink(value: NavDestination.user(uid: topic.creator.uid)) {
              Text(topic.creator.nickname)
                .lineLimit(1)
                .foregroundStyle(.accent)
            }.buttonStyle(.plain)
          }.font(.footnote)
        }.padding(.top, 2)
      }
    }
    .animation(.default, value: topics)
  }
}

#Preview {
  let container = mockContainer()

  let subject = Subject.previewAnime
  container.mainContext.insert(subject)

  return ScrollView {
    LazyVStack(alignment: .leading) {
      SubjectTopicsView(subjectId: subject.subjectId)
        .environment(Notifier())
        .modelContainer(container)
    }
  }.padding()
}
