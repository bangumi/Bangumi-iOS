//
//  SubjectTopicsView.swift
//  Chobits
//
//  Created by Chuan Chuan on 2024/10/5.
//

import SwiftData
import SwiftUI

struct SubjectTopicsView: View {
  @ObservableModel var subject: Subject

  @State private var loaded: Bool = false
  @State private var refreshing: Bool = false

  func refresh() {
    if loaded {
      return
    }
    refreshing = true
    Task {
      do {
        let resp = try await Chii.shared.getSubjectTopics(subject.subjectId, limit: 5)
        subject.topics = resp.data
      } catch {
        Notifier.shared.alert(error: error)
      }
      refreshing = false
      loaded = true
    }
  }

  var body: some View {
    VStack(spacing: 2) {
      HStack(alignment: .bottom) {
        Text("讨论版")
          .foregroundStyle(subject.topics.count > 0 ? .primary : .secondary)
          .font(.title3)
          .onAppear(perform: refresh)
        if refreshing {
          ProgressView()
        }
        Spacer()
        if subject.topics.count > 0 {
          NavigationLink(value: NavDestination.subjectTopicList(subject.subjectId)) {
            Text("更多讨论 »").font(.caption)
          }.buttonStyle(.navLink)
        }
      }
      Divider()
    }.padding(.top, 5)
    if subject.topics.count == 0 {
      HStack {
        Spacer()
        Text("暂无讨论")
          .font(.caption)
          .foregroundStyle(.secondary)
        Spacer()
      }.padding(.bottom, 5)
    }
    VStack {
      ForEach(subject.topics) { topic in
        VStack {
          HStack {
            NavigationLink(value: NavDestination.topic(topic)) {
              Text("\(topic.title)")
                .font(.callout)
                .lineLimit(1)
            }.buttonStyle(.navLink)
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
            }.buttonStyle(.navLink)
          }.font(.footnote)
        }.padding(.top, 2)
      }
    }
    .animation(.default, value: subject.topics)
  }
}

#Preview {
  let container = mockContainer()

  let subject = Subject.previewAnime
  container.mainContext.insert(subject)

  return ScrollView {
    LazyVStack(alignment: .leading) {
      SubjectTopicsView(subject: subject)
        .modelContainer(container)
    }
  }.padding()
}
