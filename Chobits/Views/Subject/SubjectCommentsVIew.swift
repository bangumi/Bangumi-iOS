//
//  SubjectCommentsVIew.swift
//  Chobits
//
//  Created by Chuan Chuan on 2024/10/5.
//

import SwiftData
import SwiftUI

struct SubjectCommentsView: View {
  let subjectId: Int

  @State private var loaded: Bool = false
  @State private var refreshing: Bool = false
  @State private var comments: [SubjectCommentDTO] = []

  @Query private var subjects: [Subject]
  private var subject: Subject? { subjects.first }

  init(subjectId: Int) {
    self.subjectId = subjectId
    _subjects = Query(
      filter: #Predicate<Subject> {
        $0.subjectId == subjectId
      })
  }

  func refresh() {
    if loaded {
      return
    }
    refreshing = true
    Task {
      do {
        let resp = try await Chii.shared.getSubjectComments(subjectId, limit: 10)
        comments = resp.data
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
        Text("吐槽箱")
          .foregroundStyle(comments.count > 0 ? .primary : .secondary)
          .font(.title3)
          .onAppear(perform: refresh)
        if refreshing {
          ProgressView()
        }
        Spacer()
        if comments.count > 0 {
          NavigationLink(value: NavDestination.subjectCommentList(subjectId: subjectId)) {
            Text("更多吐槽 »").font(.caption).foregroundStyle(.linkText)
          }.buttonStyle(.plain)
        }
      }
      Divider()
    }.padding(.top, 5)
    if comments.count == 0 {
      HStack {
        Spacer()
        Text("暂无吐槽")
          .font(.caption)
          .foregroundStyle(.secondary)
        Spacer()
      }.padding(.bottom, 5)
    }
    VStack {
      ForEach(comments) { comment in
        HStack(alignment: .top) {
          NavigationLink(value: NavDestination.user(uid: comment.user.uid)) {
            ImageView(img: comment.user.avatar?.large, width: 32, height: 32, type: .avatar)
          }
          VStack(alignment: .leading) {
            HStack {
              NavigationLink(value: NavDestination.user(uid: comment.user.uid)) {
                Text(comment.user.nickname)
                  .font(.footnote)
                  .lineLimit(1)
                  .foregroundStyle(.linkText)
              }.buttonStyle(.plain)
              if comment.rate > 0 {
                StarsView(score: Float(comment.rate), size: 10)
              }
              Text(
                "\(comment.type.description(subject?.typeEnum)) @ \(comment.updatedAt.durationDisplay)"
              )
              .lineLimit(1)
              .font(.caption)
              .foregroundStyle(.secondary)
              Spacer()
            }
            Text(comment.comment).font(.footnote)
          }
          Spacer()
        }
        .padding(.top, 2)
      }
    }.animation(.default, value: comments)
  }
}

#Preview {
  let container = mockContainer()

  let subject = Subject.previewAnime
  container.mainContext.insert(subject)

  return ScrollView {
    LazyVStack(alignment: .leading) {
      SubjectCommentsView(subjectId: subject.subjectId)
        .modelContainer(container)
    }
  }.padding()
}
