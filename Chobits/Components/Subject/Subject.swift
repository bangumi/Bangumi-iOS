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
  var subjectId: UInt

  @EnvironmentObject var notifier: Notifier
  @EnvironmentObject var chii: ChiiClient
  @EnvironmentObject var navState: NavState

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

  func refresh() async {
    if refreshed { return }
    refreshed = true
    do {
      try await chii.loadSubject(subjectId)
      try await chii.loadUserCollection(subjectId)
      try await chii.loadEpisodes(subjectId)
    } catch {
      notifier.alert(error: error)
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
              SubjectBookChaptersView(subjectId: subjectId)
            case .anime, .real:
              EpisodeGridView(subjectId: subjectId)
            default:
              EmptyView()
            }

            Divider()
            SubjectSummaryView(subjectId: subjectId)

            Spacer()
          }
        }.padding()
      } else {
        NotFoundView()
      }
    }
    .onAppear {
      Task(priority: .background) {
        await refresh()
      }
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
    .environmentObject(ChiiClient(container: container, mock: .anime))
    .modelContainer(container)
}
