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
  @AppStorage("isAuthenticated") var isAuthenticated: Bool = false

  @Environment(Notifier.self) private var notifier
  @Environment(ChiiClient.self) private var chii

  @State private var refreshed: Bool = false

  @Query
  private var subjects: [Subject]
  var subject: Subject? { subjects.first }

  init(subjectId: UInt) {
    self.subjectId = subjectId
    let predicate = #Predicate<Subject> {
      $0.subjectId == subjectId
    }
    _subjects = Query(filter: predicate, sort: \Subject.subjectId)
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

  func refreshAll() async {
    do {
      try await chii.loadSubject(subjectId)
      try await chii.loadEpisodes(subjectId)
      try await chii.loadSubjectCharacters(subjectId)
      try await chii.loadSubjectRelations(subjectId)
      try await chii.db.save()
    } catch {
      notifier.alert(error: error)
    }
  }

  var body: some View {
    Section {
      if let subject = subject {
        ScrollView(showsIndicators: false) {
          LazyVStack(alignment: .leading) {
            SubjectHeaderView(subjectId: subjectId)

            if isAuthenticated {
              SubjectCollectionView(subjectId: subjectId)
            }

            switch subject.typeEnum {
            case .anime, .real:
              EpisodeGridView(subjectId: subjectId)
            default:
              EmptyView()
            }

            SubjectSummaryView(subjectId: subjectId).padding(.vertical, 2)

            SubjectCharactersView(subjectId: subjectId)

            SubjectRelationsView(subjectId: subjectId)

            Spacer()
          }
        }
        .padding(.horizontal, 8)
        .refreshable {
          await refreshAll()
        }
        .toolbar {
          ToolbarItem(placement: .topBarTrailing) {
            ShareLink(item: shareLink) {
              Label("Share", systemImage: "square.and.arrow.up")
            }
          }
        }
        .navigationTitle(subject.name)
        .navigationBarTitleDisplayMode(.inline)
      } else if refreshed {
        NotFoundView()
      } else {
        ProgressView()
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
    SubjectView(subjectId: subject.subjectId)
      .environment(Notifier())
      .environment(ChiiClient(modelContainer: container, mock: .anime))
      .modelContainer(container)
  }
}
