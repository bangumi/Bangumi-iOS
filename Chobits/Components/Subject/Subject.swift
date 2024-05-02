//
//  Subject.swift
//  Chobits
//
//  Created by Chuan Chuan on 2024/4/27.
//

import SwiftData
import SwiftUI

struct SubjectView: View {
  @EnvironmentObject var notifier: Notifier
  @EnvironmentObject var chii: ChiiClient
  @Environment(\.modelContext) var modelContext

  @State private var subjectId: UInt
  @StateObject private var page: PageStatus = PageStatus()
  @Query private var subjects: [Subject]

  private var subject: Subject? { subjects.first }

  init(sid: UInt) {
    let predicate = #Predicate<Subject> { subject in
      subject.id == sid
    }
    _subjects = Query(filter: predicate)
    self.subjectId = sid
  }

  func fetchSubject() {
    if !self.page.start() {
      return
    }
    let actor = BackgroundActor(modelContainer: modelContext.container)
    Task {
      do {
        let resp = try await chii.getSubject(sid: self.subjectId)

        // 对于合并的条目，可能搜索返回的 ID 跟 API 拿到的 ID 不同
        // 我们直接返回 404 防止其他问题
        // 后面可以考虑直接跳转到页面
        if self.subjectId != resp.id {
          self.page.missing()
          return
        }

        try await actor.insert(subjects: [resp])
        self.page.success()
      } catch ChiiError.notFound(_) {
        if let subject = subject {
          modelContext.delete(subject)
        }
        self.page.missing()
      } catch {
        notifier.alert(message: "\(error)")
        self.page.finish()
      }
    }
  }

  var body: some View {
    Section {
      if let subject = subject {
        ScrollView {
          LazyVStack(alignment: .leading) {
            SubjectHeaderView(subject: subject)
            if chii.isAuthenticated {
              SubjectCollectionView(subject: subject)
            }
            if !subject.summary.isEmpty {
              Divider()
              SubjectSummaryView(subject: subject)
            }
            SubjectTagView(subject: subject)
            Spacer()
          }
        }.padding()
      } else {
        if page.empty {
          NotFoundView()
        } else {
          ProgressView()
        }
      }
    }.onAppear(perform: fetchSubject)
  }
}

// .anime 12
// .book 497
#Preview {
  let config = ModelConfiguration(isStoredInMemoryOnly: true)
  let container = try! ModelContainer(
    for: Subject.self, UserSubjectCollection.self, configurations: config)

  return SubjectView(sid: 497)
    .environmentObject(Notifier())
    .environmentObject(ChiiClient(mock: .book))
    .modelContainer(container)
}
