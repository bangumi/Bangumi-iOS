//
//  SubjectView.swift
//  Chobits
//
//  Created by Chuan Chuan on 2024/4/27.
//

import OSLog
import SwiftData
import SwiftUI

struct SubjectView: View {
  var subjectId: UInt

  @AppStorage("shareDomain") var shareDomain: String = ShareDomain.chii.label

  @EnvironmentObject var notifier: Notifier
  @EnvironmentObject var chii: ChiiClient

  @State private var refreshed: Bool = false

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

  var shareLink: URL {
    URL(string: "https://\(shareDomain)/subject/\(subjectId)")!
  }

  func refresh() async {
    if refreshed { return }
    refreshed = true

    do {
      try await chii.loadSubject(subjectId)
      try await chii.db.save()
    } catch {
      notifier.alert(error: error)
      return
    }
  }

  var body: some View {
    Section {
      if let subject = subject {
        ScrollView {
          LazyVStack(alignment: .leading) {
            SubjectHeaderView(subjectId: subjectId)

            if chii.isAuthenticated {
              SubjectCollectionView(subjectId: subjectId)
            }

            switch subject.typeEnum {
            case .book:
              if chii.isAuthenticated {
                SubjectBookChaptersView(subjectId: subjectId)
              }
            case .anime, .real:
              EpisodeGridView(subjectId: subjectId)
            default:
              EmptyView()
            }
            Divider()

            SubjectSummaryView(subjectId: subjectId)

            SubjectCharactersView(subjectId: subjectId)

            Divider()
            SubjectRelationsView(subjectId: subjectId)

            Spacer()
          }
        }.padding(.horizontal, 8)
      } else {
        NotFoundView()
      }
    }
    .toolbar {
      ToolbarItem(placement: .navigationBarTrailing) {
        ShareLink(item: shareLink) {
          Label("Share", systemImage: "square.and.arrow.up")
        }
      }
    }
    .navigationTitle(subject?.name ?? "条目")
    .navigationBarTitleDisplayMode(.inline)
    .onAppear {
      Task(priority: .background) {
        await refresh()
      }
    }
  }
}

#Preview {
  let container = mockContainer()

  let collection = UserSubjectCollection.previewAnime
  let subject = Subject.previewAnime
  let episodes = Episode.previewList

  container.mainContext.insert(collection)
  container.mainContext.insert(subject)
  for episode in episodes {
    container.mainContext.insert(episode)
  }

  return NavigationStack {
    SubjectView(subjectId: subject.id)
      .environmentObject(Notifier())
      .environment(ChiiClient(container: container, mock: .anime))
      .modelContainer(container)
  }
}
