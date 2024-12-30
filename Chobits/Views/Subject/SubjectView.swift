import BBCode
import OSLog
import SwiftData
import SwiftUI

struct SubjectView: View {
  let subjectId: Int

  @AppStorage("isolationMode") var isolationMode: Bool = false
  @AppStorage("isAuthenticated") var isAuthenticated: Bool = false
  @AppStorage("profile") var profile: Profile = Profile()

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
          try await Chii.shared.loadUserSubjectCollection(
            username: profile.username, subjectId: subjectId)
        }
      }

      Task {
        let resp = try await Chii.shared.getSubjectCharacters(subjectId, limit: 12)
        if subject?.characters != resp.data {
          subject?.characters = resp.data
        }
      }
      if subject?.typeEnum == .book, subject?.series ?? false {
        Task {
          let resp = try await Chii.shared.getSubjectRelations(
            subjectId, offprint: true, limit: 100)
          if subject?.offprints != resp.data {
            subject?.offprints = resp.data
          }
        }
      }
      Task {
        let resp = try await Chii.shared.getSubjectRelations(subjectId, limit: 10)
        if subject?.relations != resp.data {
          subject?.relations = resp.data
        }
      }
      Task {
        let resp = try await Chii.shared.getSubjectRecs(subjectId, limit: 10)
        if subject?.recs != resp.data {
          subject?.recs = resp.data
        }
      }
      if !isolationMode {
        Task {
          let resp = try await Chii.shared.getSubjectReviews(subjectId, limit: 5)
          if subject?.reviews != resp.data {
            subject?.reviews = resp.data
          }
        }
        Task {
          let resp = try await Chii.shared.getSubjectTopics(subjectId, limit: 5)
          if subject?.topics != resp.data {
            subject?.topics = resp.data
          }
        }
        Task {
          let resp = try await Chii.shared.getSubjectComments(subjectId, limit: 10)
          if subject?.comments != resp.data {
            subject?.comments = resp.data
          }
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
  @AppStorage("shareDomain") var shareDomain: ShareDomain = .chii
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

        BBCodeView(subject.summary, textSize: 14)
          .padding(2)
          .tint(.linkText)
          .textSelection(.enabled)

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
