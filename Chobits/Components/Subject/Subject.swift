//
//  Subject.swift
//  Chobits
//
//  Created by Chuan Chuan on 2024/4/27.
//

import SwiftData
import SwiftUI

struct SubjectView: View {
  let subjectId: UInt

  @EnvironmentObject var notifier: Notifier
  @EnvironmentObject var chii: ChiiClient
  @Environment(\.modelContext) var modelContext

  @StateObject private var page: PageStatus = PageStatus()

  @Query
  private var subjects: [Subject]
  private var subject: Subject? { subjects.first }

  init(subjectId: UInt) {
    self.subjectId = subjectId
    let predicate = #Predicate<Subject> {
      $0.id == subjectId
    }
    _subjects = Query(filter: predicate, sort: \Subject.id)
  }

  func updateSubject() async {
    if !self.page.start() {
      return
    }
    let actor = BackgroundActor(container: modelContext.container)
    do {
      let subject = try await chii.getSubject(sid: self.subjectId)

      // 对于合并的条目，可能搜索返回的 ID 跟 API 拿到的 ID 不同
      // 我们直接返回 404 防止其他问题
      // 后面可以考虑直接跳转到页面
      if self.subjectId != subject.id {
        self.page.missing()
        return
      }

      await actor.insert(data: subject)
      try await actor.save()
      self.page.success()
    } catch ChiiError.notFound(_) {
      if let subject = subject {
        await actor.delete(data: subject)
      }
      self.page.missing()
    } catch {
      notifier.alert(error: error)
      self.page.finish()
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
            } else {
              switch subject.typeEnum {
              case .anime, .music, .real:
                EpisodeGridView(subject: subject)
              default:
                EmptyView()
              }
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
    }.task {
      await updateSubject()
    }
  }
}

// .anime 12
// .book 497
#Preview {
  let config = ModelConfiguration(isStoredInMemoryOnly: true)
  let container = try! ModelContainer(
    for: UserSubjectCollection.self, Subject.self, Episode.self,
    configurations: config)

  return SubjectView(subjectId: 12)
    .environmentObject(Notifier())
    .environmentObject(ChiiClient(mock: .anime))
    .modelContainer(container)
}
