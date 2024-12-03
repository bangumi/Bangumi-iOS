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
  var subjectId: Int

  @AppStorage("shareDomain") var shareDomain: String = ShareDomain.chii.label
  @AppStorage("isolationMode") var isolationMode: Bool = false
  @AppStorage("isAuthenticated") var isAuthenticated: Bool = false

  @State private var refreshed: Bool = false

  @Query
  private var subjects: [Subject]
  var subject: Subject? { subjects.first }

  init(subjectId: Int) {
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
    do {
      if isAuthenticated {
        let updated = try await Chii.shared.loadUserSubjectCollection(subjectId)
        if !updated {
          try await Chii.shared.loadSubject(subjectId)
        }
      } else {
        try await Chii.shared.loadSubject(subjectId)
      }
    } catch {
      Notifier.shared.alert(error: error)
      return
    }
    refreshed = true
  }

  var body: some View {
    Section {
      if let subject = subject {
        ScrollView(showsIndicators: false) {
          LazyVStack(alignment: .leading) {
            SubjectHeaderView(subject: subject)

            switch subject.typeEnum {
            case .anime, .real:
              EpisodeGridView(subjectId: subjectId)
            default:
              EmptyView()
            }
            if isAuthenticated {
              SubjectCollectionView(subject: subject)
            }

            SubjectSummaryView(subject: subject)

            SubjectCharactersView(subjectId: subjectId)
            SubjectRelationsView(subjectId: subjectId, series: subject.series)

            SubjectRecsView(subjectId: subjectId)

            if !isolationMode {
              SubjectTopicsView(subjectId: subjectId)
              SubjectCommentsView(subjectId: subjectId)
            }

            Spacer()
          }.padding(.horizontal, 8)
        }
        .toolbar {
          ToolbarItem(placement: .topBarTrailing) {
            Menu {
              ShareLink(item: shareLink) {
                Label("分享", systemImage: "square.and.arrow.up")
              }
            } label: {
              Image(systemName: "ellipsis.circle")
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
      .modelContainer(container)
  }
}
