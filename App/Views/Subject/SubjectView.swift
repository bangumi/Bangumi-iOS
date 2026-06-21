import OSLog
import SwiftUI

struct SubjectView: View {
  let subjectId: Int

  @AppStorage("isolationMode") var isolationMode: Bool = false
  @AppStorage("isAuthenticated") var isAuthenticated: Bool = false
  @AppStorage("titlePreference") var titlePreference: TitlePreference = .original

  @State private var refreshed: Bool = false
  @State private var refreshing: Bool = false
  @State private var subject: SubjectDTO?
  @State private var detail: SubjectDetailDTO = SubjectDetailDTO()

  private func loadCached(animated: Bool = false) async {
    do {
      let db = try await AppContext.shared.getDB()
      let cachedSubject = try await db.getSubjectDTO(subjectId)
      let cachedDetail = try await db.getSubjectDetailDTO(subjectId)
      if animated {
        withAnimation(.default) {
          subject = cachedSubject
          detail = cachedDetail
        }
      } else {
        subject = cachedSubject
        detail = cachedDetail
      }
    } catch {
      Logger.app.error("Failed to load cached subject: \(error)")
    }
  }

  func refresh(force: Bool = false) async {
    if refreshed && !force { return }
    if refreshing { return }
    withAnimation(.default) {
      refreshing = true
    }
    do {
      let item = try await SubjectRepository.loadSubject(subjectId)
      withAnimation(.default) {
        subject = item
        refreshed = true
      }
      Logger.app.debug("subject refreshed: \(subjectId)")

      try await SubjectRepository.loadSubjectDetails(
        subjectId,
        offprints: item.type == .book && item.series,
        social: !isolationMode
      )
      await loadCached(animated: true)
    } catch {
      Notifier.shared.alert(error: error)
      withAnimation(.default) {
        refreshed = true
      }
    }
    withAnimation(.default) {
      refreshing = false
    }
  }

  var body: some View {
    Section {
      if let subject = subject {
        SubjectDetailView(subject: subject, detail: detail) {
          await loadCached()
        }
      } else if refreshed {
        NotFoundView()
      } else {
        ProgressView()
      }
    }
    .task {
      await loadCached()
      await refresh()
    }
    .modifier(ZoomTransitionModifier(zoomID: ZoomNavigationID(type: .subject, id: subjectId)))
  }
}

struct SubjectDetailView: View {
  @AppStorage("shareDomain") var shareDomain: ShareDomain = .chii
  @AppStorage("isolationMode") var isolationMode: Bool = false
  @AppStorage("isAuthenticated") var isAuthenticated: Bool = false
  @AppStorage("titlePreference") var titlePreference: TitlePreference = .original

  let subject: SubjectDTO
  let detail: SubjectDetailDTO
  let reload: () async -> Void

  @State private var showCreateTopic: Bool = false
  @State private var showIndexPicker: Bool = false
  @State private var showRatingSheet: Bool = false

  var shareLink: URL {
    URL(string: "\(shareDomain.url)/subject/\(subject.id)")!
  }

  var body: some View {
    ScrollView(showsIndicators: false) {
      VStack(alignment: .leading) {
        SubjectHeaderView(subject: subject) {
          showRatingSheet = true
        }

        if isAuthenticated {
          SubjectCollectionView(subject: subject, reload: reload)
        }

        if subject.type == .anime || subject.type == .real {
          EpisodeGridView(
            subjectId: subject.id,
            subjectCollectionType: subject.ctypeEnum
          )
        }

        SubjectSummaryView(subject: subject)

        if subject.type == .music {
          EpisodeDiscView(subjectId: subject.id)
        } else {
          SubjectCharactersView(subjectId: subject.id, characters: detail.characters)
        }

        if subject.type == .book, subject.series {
          SubjectOffprintsView(subjectId: subject.id, offprints: detail.offprints)
        }

        SubjectRelationsView(subjectId: subject.id, relations: detail.relations)

        SubjectRecsView(subjectId: subject.id, recs: detail.recs)

        SubjectIndexsView(subjectId: subject.id, indexes: detail.indexes)

        if !isolationMode {
          SubjectCollectsView(subject: subject, collects: detail.collects)
          SubjectReviewsView(subjectId: subject.id, reviews: detail.reviews)
          SubjectTopicsView(subjectId: subject.id, topics: detail.topics)
          SubjectCommentsView(
            subjectId: subject.id, subjectType: subject.type, comments: detail.comments)
        }

        Spacer()
      }.padding(.horizontal, 8)
    }
    .sheet(isPresented: $showCreateTopic) {
      CreateTopicBoxSheet(type: .subject(subject.id)) {
        Task {
          try? await SubjectRepository.loadSubjectDetails(
            subject.id, offprints: false, social: true)
          await reload()
        }
      }
    }
    .sheet(isPresented: $showIndexPicker) {
      IndexPickerSheet(
        category: .subject,
        itemId: subject.id,
        itemTitle: subject.title(with: titlePreference)
      )
    }
    .sheet(isPresented: $showRatingSheet) {
      SubjectRatingSheet(subject: subject)
    }
    .navigationTitle(subject.name)
    .navigationBarTitleDisplayMode(.inline)
    .toolbar {
      ToolbarItem(placement: .topBarTrailing) {
        Menu {
          NavigationLink(value: NavDestination.subjectStaffList(subject.id)) {
            Label("制作人员", systemImage: "person.3")
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
          Image(systemName: "ellipsis")
        }
      }
    }
    .handoff(url: shareLink, title: subject.name)
  }
}
