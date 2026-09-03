import SwiftUI

struct GlassSubjectDetailView: View {
  @AppStorage("shareDomain") var shareDomain: ShareDomain = .chii
  @AppStorage("isolationMode") var isolationMode: Bool = false
  @AppStorage("isAuthenticated") var isAuthenticated: Bool = false
  @AppStorage("profile") var profile: Profile = Profile()
  @AppStorage("titlePreference") var titlePreference: TitlePreference = .original

  let subject: SubjectDTO
  let detail: SubjectDetailDTO
  let reload: () async -> Void

  @Environment(\.theme) private var theme

  @State private var showCreateTopic: Bool = false
  @State private var showIndexPicker: Bool = false
  @State private var showRatingSheet: Bool = false
  @State private var showWikiEdit: Bool = false
  @State private var showWikiLock: Bool = false
  @State private var showEpisodeWiki: Bool = false

  private var shareLink: URL {
    URL(string: "\(shareDomain.url)/subject/\(subject.id)")!
  }

  var body: some View {
    ScrollView(showsIndicators: false) {
      VStack(alignment: .leading, spacing: theme.metrics.listSpacing) {
        GlassSubjectHeader(subject: subject) {
          showRatingSheet = true
        }

        if isAuthenticated {
          GlassSubjectCollection(subject: subject, reload: reload)
        }

        if subject.type == .anime || subject.type == .real {
          GlassEpisodeGridView(
            subjectId: subject.id,
            subjectCollectionType: subject.ctypeEnum
          )
        }

        GlassSubjectSummary(subject: subject)

        if subject.type == .music {
          GlassSubjectDiscs(subjectId: subject.id)
        } else {
          GlassSubjectCharacters(subjectId: subject.id, characters: detail.characters)
        }

        if subject.type == .book, subject.series {
          GlassSubjectOffprints(subjectId: subject.id, offprints: detail.offprints)
        }

        GlassSubjectRelations(subjectId: subject.id, relations: detail.relations)

        GlassSubjectRecs(subjectId: subject.id, recs: detail.recs)

        GlassSubjectIndexes(subjectId: subject.id, indexes: detail.indexes)

        if !isolationMode {
          GlassSubjectCollects(subject: subject, collects: detail.collects)
          GlassSubjectReviews(subjectId: subject.id, reviews: detail.reviews)
          GlassSubjectTopics(subjectId: subject.id, topics: detail.topics)
          GlassSubjectComments(
            subjectId: subject.id, subjectType: subject.type, comments: detail.comments)
        }

        GlassSubjectFooter(subjectId: subject.id)
      }
      .padding(.horizontal, theme.metrics.screenPadding)
      .padding(.bottom, 26)
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
      GlassSubjectRatingSheet(subject: subject)
    }
    .sheet(isPresented: $showWikiEdit) {
      SubjectWikiEditSheet(subjectId: subject.id) {
        Task {
          await reload()
        }
      }
    }
    .sheet(isPresented: $showWikiLock) {
      SubjectWikiLockSheet(subjectId: subject.id, locked: subject.locked) {
        Task {
          await reload()
        }
      }
    }
    .sheet(isPresented: $showEpisodeWiki) {
      SubjectEpisodeWikiSheet(subjectId: subject.id) {
        Task {
          try? await SubjectRepository.loadSubjectDetails(
            subject.id,
            offprints: subject.type == .book && subject.series,
            social: !isolationMode
          )
          await reload()
        }
      }
    }
    .navigationTitle(subject.name)
    .navigationBarTitleDisplayMode(.inline)
    .toolbar {
      ToolbarItem(placement: .principal) {
        Text(subject.name)
          .font(.subheadline.weight(.heavy))
          .foregroundStyle(.primary)
          .lineLimit(1)
          .truncationMode(.tail)
      }
      ToolbarItem(placement: .topBarTrailing) {
        Menu {
          menuItems
        } label: {
          ToolbarCircle {
            Image(systemName: "ellipsis")
              .font(.callout.weight(.bold))
          }
        }
      }
    }
    .handoff(url: shareLink, title: subject.name)
  }

  @ViewBuilder
  private var menuItems: some View {
    NavigationLink(value: NavDestination.subjectStaffList(subject.id)) {
      Label("制作人员", systemImage: "person.3")
    }
    if isAuthenticated && profile.canAccessWikiTools {
      Menu {
        wikiMenuItems
      } label: {
        Label("Wiki", systemImage: "pencil.and.list.clipboard")
      }
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
  }

  @ViewBuilder
  private var wikiMenuItems: some View {
    if profile.canEditSubjectWiki {
      Button {
        showWikiEdit = true
      } label: {
        Label("编辑 Wiki", systemImage: "pencil")
      }
    }
    if profile.groupEnum.canEditEpisodeWiki {
      Button {
        showEpisodeWiki = true
      } label: {
        Label("章节 Wiki", systemImage: "list.number")
      }
    }
    if profile.groupEnum.canLockSubjectWiki {
      Button {
        showWikiLock = true
      } label: {
        Label(
          subject.locked ? "解锁条目" : "锁定条目",
          systemImage: subject.locked ? "lock.open" : "lock"
        )
      }
    }
    if profile.canEditSubjectWiki {
      NavigationLink(value: NavDestination.subjectWikiCovers(subject.id)) {
        Label("封面", systemImage: "photo")
      }
    }
    Divider()
    NavigationLink(value: NavDestination.wikiHistory(.subject, subject.id)) {
      Label("条目信息历史", systemImage: WikiHistoryKind.subject.icon)
    }
    NavigationLink(value: NavDestination.wikiHistory(.subjectRelations, subject.id)) {
      Label("关联条目历史", systemImage: WikiHistoryKind.subjectRelations.icon)
    }
    NavigationLink(value: NavDestination.wikiHistory(.subjectCharacters, subject.id)) {
      Label("关联角色历史", systemImage: WikiHistoryKind.subjectCharacters.icon)
    }
    NavigationLink(value: NavDestination.wikiHistory(.subjectPersons, subject.id)) {
      Label("制作人员历史", systemImage: WikiHistoryKind.subjectPersons.icon)
    }
  }
}
