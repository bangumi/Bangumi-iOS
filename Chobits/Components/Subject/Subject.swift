//
//  Subject.swift
//  Chobits
//
//  Created by Chuan Chuan on 2024/4/27.
//

import OSLog
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
  var subject: Subject? { subjects.first }

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
    Logger.subject.info("updating subject: \(self.subjectId)")
    let actor = BackgroundActor(container: modelContext.container)
    do {
      let item = try await chii.getSubject(sid: self.subjectId)

      // 对于合并的条目，可能搜索返回的 ID 跟 API 拿到的 ID 不同
      // 我们直接返回 404 防止其他问题
      // 后面可以考虑直接跳转到页面
      if self.subjectId != item.id {
        Logger.subject.warning("subject id mismatch: \(self.subjectId) != \(item.id)")
        self.page.missing()
        return
      }

      Logger.subject.info("fetched subject: \(item.id)")
      let subject = Subject(item: item)
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
            SubjectHeaderView(subjectId: subject.id)

            if chii.isAuthenticated {
              SubjectCollectionView(subjectId: subject.id)
            }

            switch subject.typeEnum  {
            case .book:
              SubjectBookChaptersView(subjectId: subjectId)
            case .anime, .real:
              EpisodeGridView(subjectId: subjectId)
            default:
              EmptyView()
            }

            if !subject.summary.isEmpty {
              Divider()
              SubjectSummaryView(subjectId: subject.id)
            }
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
    }.task(priority: .background) {
      await updateSubject()
    }
  }
}

#Preview {
  let config = ModelConfiguration(isStoredInMemoryOnly: true)
  let container = try! ModelContainer(
    for: UserSubjectCollection.self, Subject.self, Episode.self,
    configurations: config)

  let collection = UserSubjectCollection.previewAnime
  let subject = Subject.previewAnime
  let episodes = Episode.previewList

  container.mainContext.insert(collection)
  container.mainContext.insert(subject)
  for episode in episodes {
    container.mainContext.insert(episode)
  }

  return SubjectView(subjectId: subject.id)
    .environmentObject(Notifier())
    .environmentObject(ChiiClient(mock: .anime))
    .modelContainer(container)
}
