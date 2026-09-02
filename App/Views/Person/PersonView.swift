import OSLog
import SwiftUI

struct PersonView: View {
  var personId: Int
  var zoom = false

  @AppStorage("shareDomain") var shareDomain: ShareDomain = .chii
  @AppStorage("isAuthenticated") var isAuthenticated: Bool = false
  @AppStorage("profile") var profile: Profile = Profile()
  @AppStorage("titlePreference") var titlePreference: TitlePreference = .original

  @State private var refreshed: Bool = false
  @State private var person: PersonDTO?
  @State private var detail: PersonDetailDTO = PersonDetailDTO()
  @State private var showIndexPicker: Bool = false
  @State private var showWikiEdit: Bool = false
  @State private var showPortraitUpload: Bool = false

  @Environment(\.theme) private var theme

  var shareLink: URL {
    URL(string: "\(shareDomain.url)/person/\(personId)")!
  }

  var title: String {
    guard let person = person else {
      return "人物"
    }
    return person.title(with: titlePreference)
  }

  private func loadCached(animated: Bool = false) async {
    do {
      let db = try await AppContext.shared.getDB()
      let cachedPerson = try await db.getPersonDTO(personId)
      let cachedDetail = try await db.getPersonDetailDTO(personId)
      if animated {
        withAnimation(.default) {
          person = cachedPerson
          detail = cachedDetail
        }
      } else {
        person = cachedPerson
        detail = cachedDetail
      }
    } catch {
      Logger.app.error("Failed to load cached person: \(error)")
    }
  }

  func refresh() async {
    do {
      try await PersonRepository.loadPerson(personId)
      await loadCached(animated: true)
      withAnimation(.default) {
        refreshed = true
      }

      try await PersonRepository.loadPersonDetails(personId)
      await loadCached(animated: true)
    } catch {
      Notifier.shared.alert(error: error)
      return
    }
  }

  private var classicBody: some View {
    Section {
      if let person = person {
        ScrollView {
          VStack(alignment: .leading) {
            PersonDetailView(person: person, detail: detail) {
              await loadCached()
            }
          }.padding(.horizontal, 8)
        }
        .refreshable {
          Task {
            await refresh()
          }
        }
        .sheet(isPresented: $showIndexPicker) {
          IndexPickerSheet(
            category: .person,
            itemId: personId,
            itemTitle: title
          )
        }
      } else if refreshed {
        NotFoundView()
      } else {
        ProgressView()
      }
    }
  }

  @ViewBuilder
  private var glassBody: some View {
    if let person = person {
      GlassPersonDetailView(person: person, detail: detail) {
        await loadCached()
      }
      .refreshable {
        Task {
          await refresh()
        }
      }
      .sheet(isPresented: $showIndexPicker) {
        IndexPickerSheet(
          category: .person,
          itemId: personId,
          itemTitle: title
        )
      }
    } else if refreshed {
      NotFoundView()
    } else {
      ProgressView()
    }
  }

  var body: some View {
    Group {
      if theme.isClassic {
        classicBody
      } else {
        glassBody
      }
    }
    .task {
      await loadCached()
      await refresh()
    }
    .navigationTitle(title)
    .navigationBarTitleDisplayMode(.inline)
    .toolbar {
      ToolbarItem(placement: .topBarTrailing) {
        Menu {
          if isAuthenticated && profile.groupEnum.canAccessWikiTools {
            Menu {
              if profile.groupEnum.canEditMonoWiki {
                Button {
                  showWikiEdit = true
                } label: {
                  Label("编辑 Wiki", systemImage: "pencil")
                }
                Button {
                  showPortraitUpload = true
                } label: {
                  Label("上传肖像", systemImage: "photo")
                }
                Divider()
              }
              NavigationLink(value: NavDestination.wikiHistory(.person, personId)) {
                Label("人物信息历史", systemImage: WikiHistoryKind.person.icon)
              }
              NavigationLink(value: NavDestination.wikiHistory(.personSubjects, personId)) {
                Label("参与作品历史", systemImage: WikiHistoryKind.personSubjects.icon)
              }
              NavigationLink(value: NavDestination.wikiHistory(.personCasts, personId)) {
                Label("出演角色历史", systemImage: WikiHistoryKind.personCasts.icon)
              }
            } label: {
              Label("Wiki", systemImage: "pencil.and.list.clipboard")
            }
            Divider()
          }
          Button {
            showIndexPicker = true
          } label: {
            Label("收藏", systemImage: "book")
          }
          .disabled(!isAuthenticated)
          ShareLink(item: shareLink) {
            Label("分享", systemImage: "square.and.arrow.up")
          }
        } label: {
          Image(systemName: "ellipsis")
        }
      }
    }
    .sheet(isPresented: $showWikiEdit) {
      PersonWikiEditSheet(personId: personId) {
        Task {
          await loadCached()
        }
      }
    }
    .sheet(isPresented: $showPortraitUpload) {
      WikiPortraitUploadSheet(kind: .person, entityId: personId) {
        Task {
          await loadCached()
        }
      }
    }
    .handoff(url: shareLink, title: title)
    .modifier(
      ZoomTransitionModifier(
        zoomID: ZoomNavigationID(type: .person, id: personId),
        enabled: zoom || theme.isClassic
      )
    )
  }
}

struct PersonDetailView: View {
  let person: PersonDTO
  let detail: PersonDetailDTO
  let reload: () async -> Void

  @AppStorage("isolationMode") private var isolationMode = false
  @State private var updating: Bool = false

  var careers: String {
    let vals = Set(person.career).sorted { $0.rawValue < $1.rawValue }.map(\.description)
    return vals.joined(separator: " / ")
  }

  func collect() async {
    updating = true
    defer { updating = false }
    do {
      if person.collectedAt ?? 0 == 0 {
        try await PersonRepository.collectPerson(person.id)
      } else {
        try await PersonRepository.uncollectPerson(person.id)
      }
      await reload()
      UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    } catch {
      Notifier.shared.alert(error: error)
    }
  }

  var body: some View {
    /// title
    Text(person.name)
      .font(.title2.bold())
      .multilineTextAlignment(.leading)

    /// header
    HStack(alignment: .top) {
      ImageView(img: person.images?.resize(.r400))
        .imageStyle(width: 120, height: 120, alignment: .top)
        .imageType(.person)
        .imageNSFW(person.nsfw)
        .enableImagePreview(
          person.images?.large, zoomID: ZoomNavigationID(type: .person, id: person.id)
        )
        .padding(4)
        .shadow(radius: 4)
      VStack(alignment: .leading) {
        HStack {
          Label(person.type.description, systemImage: person.type.icon)
            .font(.footnote)
            .foregroundStyle(.secondary)
          Spacer()
          Button {
            Task {
              await collect()
            }
          } label: {
            HeartView(collected: (person.collectedAt ?? 0) != 0, updating: updating)
          }
        }
        .buttonStyle(.explode)
        .padding(.trailing, 16)

        Spacer()
        if person.nameCN.isEmpty {
          Text(person.name)
            .multilineTextAlignment(.leading)
            .truncationMode(.middle)
            .lineLimit(2)
            .textSelection(.enabled)
        } else {
          Text(person.nameCN)
            .multilineTextAlignment(.leading)
            .truncationMode(.middle)
            .lineLimit(2)
            .textSelection(.enabled)
        }
        Spacer()

        if !careers.isEmpty {
          Text(careers)
            .font(.footnote)
            .foregroundStyle(.secondary)
            .lineLimit(1)
        }

        NavigationLink(value: NavDestination.infobox("人物信息", person.infobox)) {
          HStack {
            Text(person.info)
              .font(.caption)
              .lineLimit(2)
            Spacer()
            Image(systemName: "chevron.right")
          }
        }
        .buttonStyle(.navigation)
        .padding(.vertical, 4)

        HStack {
          Label("\(person.collects)人收藏", systemImage: "heart")
            .foregroundStyle(.secondary)
            .lineLimit(1)
          Spacer(minLength: 8)
          if !isolationMode {
            CommentListNavigationLink(
              route: CommentListRoute(parent: .person(person.id)),
              count: person.comment
            )
          }
        }
        .font(.footnote)
      }.padding(.leading, 2)
    }.frame(height: 120)

    /// summary
    BBCodeView(person.summary, textSize: 14)
      .textSelection(.enabled)
      .padding(2)
      .tint(.linkText)

    /// casts
    PersonCastsView(personId: person.id, casts: detail.casts)

    /// works
    PersonWorksView(personId: person.id, works: detail.works)

    /// relations
    PersonRelationsView(personId: person.id, relations: detail.relations)

    /// indexes
    PersonIndexsView(personId: person.id, indexes: detail.indexes)
  }
}
