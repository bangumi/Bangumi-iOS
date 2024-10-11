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
  @AppStorage("isolationMode") var isolationMode: Bool = false
  @AppStorage("isAuthenticated") var isAuthenticated: Bool = false

  @Environment(Notifier.self) private var notifier

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
      try await Chii.shared.loadSubject(subjectId)
    } catch {
      notifier.alert(error: error)
      return
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

            SubjectSummaryView(subjectId: subjectId)

            SubjectCharactersView(subjectId: subjectId)
            SubjectRelationsView(subjectId: subjectId)
            if !isolationMode {
              SubjectTopicsView(subjectId: subjectId)
              SubjectCommentsView(subjectId: subjectId)
            }

            Spacer()
          }.padding(.horizontal, 8)
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
      Task {
        await refresh()
      }
    }
  }
}

#Preview {
  let container = mockContainer()

  let collection = UserSubjectCollection.previewAnime
  let subject = Subject.previewAnime

  container.mainContext.insert(collection)
  container.mainContext.insert(subject)

  return NavigationStack {
    SubjectView(subjectId: subject.subjectId)
      .environment(Notifier())
      .modelContainer(container)
  }
}
