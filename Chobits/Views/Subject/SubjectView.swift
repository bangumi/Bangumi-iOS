//
//  SubjectView.swift
//  Chobits
//
//  Created by Chuan Chuan on 2024/4/27.
//

import Flow
import OSLog
import SwiftData
import SwiftUI

struct SubjectView: View {
  let subjectId: Int

  @AppStorage("shareDomain") var shareDomain: String = ShareDomain.chii.label
  @AppStorage("isolationMode") var isolationMode: Bool = false
  @AppStorage("isAuthenticated") var isAuthenticated: Bool = false

  @State private var refreshed: Bool = false

  @Query private var subjects: [Subject]
  var subject: Subject? { subjects.first }

  init(subjectId: Int) {
    self.subjectId = subjectId
    _subjects = Query(
      filter: #Predicate<Subject> {
        $0.subjectId == subjectId
      })
  }

  var shareLink: URL {
    URL(string: "https://\(shareDomain)/subject/\(subjectId)")!
  }

  func refresh() async {
    if refreshed { return }
    do {
      try await Chii.shared.loadSubject(subjectId)

      Task {
        let respCharacters = try await Chii.shared.getSubjectCharacters(subjectId, limit: 10)
        subject?.characters = respCharacters.data
      }
      if subject?.typeEnum == .book, subject?.series ?? false {
        Task {
          let respOffprints = try await Chii.shared.getSubjectRelations(
            subjectId, offprint: true, limit: 100)
          subject?.offprints = respOffprints.data
        }
      }
      Task {
        let respRelations = try await Chii.shared.getSubjectRelations(subjectId, limit: 10)
        subject?.relations = respRelations.data
      }
      Task {
        let respRecs = try await Chii.shared.getSubjectRecs(subjectId, limit: 10)
        subject?.recs = respRecs.data
      }
      if !isolationMode {
        Task {
          let respTopics = try await Chii.shared.getSubjectTopics(subjectId, limit: 5)
          subject?.topics = respTopics.data
        }
        Task {
          let respComments = try await Chii.shared.getSubjectComments(subjectId, limit: 5)
          subject?.comments = respComments.data
        }
      }

    } catch {
      Notifier.shared.alert(error: error)
      return
    }
    refreshed = true
  }

  var body: some View {
    let _ = Self._printChanges()
    Section {
      if let subject = subject {
        ScrollView(showsIndicators: false) {
          LazyVStack(alignment: .leading) {
            SubjectHeaderView(subjectId: subjectId)

//            if isAuthenticated {
//              SubjectCollectionView(subjectId: subjectId)
//            }

            if subject.typeEnum == .anime || subject.typeEnum == .real {
              EpisodeGridView(subjectId: subjectId)
            }

            if subject.metaTags.count > 0 {
              HFlow(alignment: .center, spacing: 4) {
                ForEach(subject.metaTags, id: \.self) { tag in
                  BorderView {
                    Text(tag)
                      .font(.footnote)
                      .lineLimit(1)
                  }.padding(1)
                }
              }.padding(.vertical, 2)
            }
            BBCodeWebView(subject.summary, textSize: 14)

            if subject.typeEnum == .music {
              EpisodeDiscView(subjectId: subjectId)
            } else {
              SubjectCharactersView(subjectId: subjectId, characters: subject.characters)
            }

            if subject.typeEnum == .book, subject.series {
              SubjectOffprintsView(subjectId: subjectId, offprints: subject.offprints)
            }

            SubjectRelationsView(subjectId: subjectId, relations: subject.relations)

            SubjectRecsView(subjectId: subjectId, recs: subject.recs)

            if !isolationMode {
              SubjectTopicsView(subjectId: subjectId, topics: subject.topics)
              SubjectCommentsView(
                subjectId: subjectId, subjectType: subject.typeEnum, comments: subject.comments)
            }

            Spacer()
          }.padding(.horizontal, 8)
        }
        .toolbar {
          ToolbarItem(placement: .topBarTrailing) {
            Menu {
              NavigationLink(value: NavDestination.subjectStaffList(subjectId)) {
                Label("制作人员", systemImage: "person.2")
              }
              NavigationLink(value: NavDestination.subjectRating(subject)) {
                Label("评分分布", systemImage: "chart.bar.xaxis")
              }
              Divider()
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
