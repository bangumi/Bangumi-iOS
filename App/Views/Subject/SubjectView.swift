import OSLog
import SwiftData
import SwiftUI

struct SubjectView: View {
  let subjectId: Int

  @AppStorage("isolationMode") var isolationMode: Bool = false
  @AppStorage("isAuthenticated") var isAuthenticated: Bool = false
  @AppStorage("titlePreference") var titlePreference: TitlePreference = .original

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
      let item = try await Chii.shared.loadSubject(subjectId)
      refreshed = true

      try await Chii.shared.loadSubjectDetails(
        subjectId,
        offprints: item.type == .book && item.series,
        social: !isolationMode
      )
    } catch {
      Notifier.shared.alert(error: error)
      refreshed = true
    }
    refreshing = false
  }

  var body: some View {
    Section {
      if let subject = subject {
        SubjectDetailView(subject: subject)
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
  @AppStorage("titlePreference") var titlePreference: TitlePreference = .original

  @Bindable var subject: Subject

  @State private var showCreateTopic: Bool = false
  @State private var showIndexPicker: Bool = false

  var shareLink: URL {
    URL(string: "\(shareDomain.url)/subject/\(subject.subjectId)")!
  }

  var body: some View {
    ScrollView(showsIndicators: false) {
      VStack(alignment: .leading) {
        SubjectHeaderView(subject: subject)

        if isAuthenticated {
          SubjectCollectionView(subject: subject)
        }

        if subject.typeEnum == .anime || subject.typeEnum == .real {
          EpisodeGridView(subjectId: subject.subjectId)
        }

        SubjectSummaryView(subject: subject)

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

        SubjectIndexsView(subjectId: subject.subjectId, indexes: subject.indexes)

        if !isolationMode {
          SubjectCollectsView(subject: subject)
          SubjectReviewsView(subjectId: subject.subjectId, reviews: subject.reviews)
          SubjectTopicsView(subjectId: subject.subjectId, topics: subject.topics)
          SubjectCommentsView(
            subjectId: subject.subjectId, subjectType: subject.typeEnum, comments: subject.comments)
        }

        Spacer()
      }.padding(.horizontal, 8)
    }
    .sheet(isPresented: $showCreateTopic) {
      CreateTopicBoxSheet(type: .subject(subject.subjectId)) {
        Task {
          try? await Chii.shared.loadSubjectDetails(
            subject.subjectId, offprints: false, social: true)
        }
      }
    }
    .sheet(isPresented: $showIndexPicker) {
      IndexPickerSheet(
        category: .subject,
        itemId: subject.subjectId,
        itemTitle: subject.title(with: titlePreference)
      )
    }
    .navigationTitle(subject.name)
    .navigationBarTitleDisplayMode(.inline)
    .toolbar {
      ToolbarItem(placement: .topBarTrailing) {
        Menu {
          NavigationLink(value: NavDestination.subjectStaffList(subject.subjectId)) {
            Label("制作人员", systemImage: "person.3")
          }
          NavigationLink(value: NavDestination.subjectRating(subject)) {
            Label("评分分布", systemImage: "chart.bar.xaxis")
          }
          if isAuthenticated {
            Divider()
            Button {
              showCreateTopic = true
            } label: {
              Label("添加新讨论", systemImage: "plus.bubble")
            }
          }
          Divider()
          if isAuthenticated {
            Button {
              showIndexPicker = true
            } label: {
              Label("收藏", systemImage: "book")
            }
          }
          ShareLink(item: shareLink) {
            Label("分享", systemImage: "square.and.arrow.up")
          }
        } label: {
          Image(systemName: "ellipsis.circle")
        }
      }
    }
    .handoff(url: shareLink, title: subject.name)
    .modifier(
      ZoomTransitionModifier(zoomID: ZoomNavigationID(type: .subject, id: subject.subjectId)))
  }
}

#Preview {
  let container = mockContainer()

  let subject = Subject.previewAnime
  container.mainContext.insert(subject)

  return NavigationStack {
    SubjectView(subjectId: subject.subjectId)
  }.modelContainer(container)
}
