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

  @AppStorage("isolationMode") var isolationMode: Bool = false
  @AppStorage("isAuthenticated") var isAuthenticated: Bool = false

  @State private var refreshed: Bool = false
  @State private var refreshing: Bool = false

  @Query private var subjects: [Subject]
  var subject: Subject? { subjects.first }

  init(subjectId: Int) {
    self.subjectId = subjectId
    _subjects = Query(filter: #Predicate<Subject> { $0.subjectId == subjectId })
  }

  func refresh() async {
    if refreshed { return }
    if refreshing { return }
    refreshing = true
    do {
      try await Chii.shared.loadSubject(subjectId)
      refreshed = true

      if isAuthenticated {
        Task {
          try await Chii.shared.loadUserSubjectCollection(subjectId)
        }
      }

      Task {
        try await Chii.shared.loadSubjectCharacters(subjectId)
      }
      if subject?.typeEnum == .book, subject?.series ?? false {
        Task {
          try await Chii.shared.loadSubjectOffprints(subjectId)
        }
      }
      Task {
        try await Chii.shared.loadSubjectRelations(subjectId)
      }
      Task {
        try await Chii.shared.loadSubjectRecs(subjectId)
      }
      if !isolationMode {
        Task {
          try await Chii.shared.loadSubjectReviews(subjectId)
        }
        Task {
          try await Chii.shared.loadSubjectTopics(subjectId)
        }
        Task {
          try await Chii.shared.loadSubjectComments(subjectId)
        }
      }
    } catch {
      Notifier.shared.alert(error: error)
      refreshed = true
    }
    refreshing = false
  }

  var body: some View {
    Section {
      if let subject = subject {
        SubjectDetailView().environment(subject)
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

struct SubjectDetailView: View {
  @AppStorage("shareDomain") var shareDomain: String = ShareDomain.chii.label
  @AppStorage("isolationMode") var isolationMode: Bool = false
  @AppStorage("isAuthenticated") var isAuthenticated: Bool = false

  @Environment(Subject.self) var subject

  var shareLink: URL {
    URL(string: "https://\(shareDomain)/subject/\(subject.subjectId)")!
  }

  var body: some View {
    ScrollView(showsIndicators: false) {
      LazyVStack(alignment: .leading) {
        SubjectHeaderView()

        if isAuthenticated {
          SubjectCollectionView(subjectId: subject.subjectId)
        }

        if subject.typeEnum == .anime || subject.typeEnum == .real {
          EpisodeGridView(subjectId: subject.subjectId)
        }

        if subject.metaTags.count > 0 {
          SubjectMetaTagsView(tags: subject.metaTags)
        }
        BBCodeWebView(subject.summary, textSize: 14)

        if subject.typeEnum == .music {
          EpisodeDiscView(subjectId: subject.subjectId)
        } else {
          SubjectCharactersView(subjectId: subject.subjectId, characters: subject.characters)
        }

        if subject.typeEnum == .book, subject.series {
          SubjectOffprintsView(subjectId: subject.subjectId, offprints: subject.offprints)
        }

        SubjectRelationsView(subjectId: subject.subjectId, relations: subject.relations)

        SubjectRecsView(subjectId: subject.subjectId, recs: subject.recs)

        if !isolationMode {
          SubjectReviewsView(subjectId: subject.subjectId, reviews: subject.reviews)
          SubjectTopicsView(subjectId: subject.subjectId, topics: subject.topics)
          SubjectCommentsView(
            subjectId: subject.subjectId, subjectType: subject.typeEnum, comments: subject.comments)
        }

        Spacer()
      }.padding(.horizontal, 8)
    }
    .toolbar {
      ToolbarItem(placement: .topBarTrailing) {
        Menu {
          NavigationLink(value: NavDestination.subjectStaffList(subject.subjectId)) {
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
  }
}

struct SubjectMetaTagsView: View {
  let tags: [String]

  var body: some View {
    HFlow(alignment: .center, spacing: 4) {
      ForEach(tags, id: \.self) { tag in
        BorderView {
          Text(tag)
            .font(.footnote)
            .lineLimit(1)
        }.padding(1)
      }
    }.padding(.vertical, 2)
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
