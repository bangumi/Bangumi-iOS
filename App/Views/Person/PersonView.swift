import BBCode
import OSLog
import SwiftUI

struct PersonView: View {
  var personId: Int

  @AppStorage("shareDomain") var shareDomain: ShareDomain = .chii
  @AppStorage("isolationMode") var isolationMode: Bool = false
  @AppStorage("isAuthenticated") var isAuthenticated: Bool = false
  @AppStorage("titlePreference") var titlePreference: TitlePreference = .original

  @State private var refreshed: Bool = false
  @State private var person: PersonDTO?
  @State private var detail: PersonDetailDTO = PersonDetailDTO()
  @State private var comments: [CommentDTO] = []
  @State private var loadingComments: Bool = false
  @State private var showCommentBox: Bool = false
  @State private var showIndexPicker: Bool = false

  var shareLink: URL {
    URL(string: "\(shareDomain.url)/person/\(personId)")!
  }

  var title: String {
    guard let person = person else {
      return "人物"
    }
    return person.title(with: titlePreference)
  }

  private func loadCached() async {
    do {
      let db = try await AppContext.shared.getDB()
      person = try await db.getPersonDTO(personId)
      detail = try await db.getPersonDetailDTO(personId)
    } catch {
      Logger.app.error("Failed to load cached person: \(error)")
    }
  }

  func refresh() async {
    do {
      try await PersonRepository.loadPerson(personId)
      await loadCached()
      refreshed = true

      if !isolationMode {
        loadingComments = true
        comments = try await PersonService.getPersonComments(personId)
        loadingComments = false
      }

      try await PersonRepository.loadPersonDetails(personId)
      await loadCached()
    } catch {
      Notifier.shared.alert(error: error)
      return
    }
  }

  var body: some View {
    Section {
      if let person = person {
        ScrollView {
          VStack(alignment: .leading) {
            PersonDetailView(person: person, detail: detail) {
              await loadCached()
            }

            /// comments
            if !isolationMode {
              VStack(alignment: .leading, spacing: 2) {
                HStack {
                  Text("吐槽箱").font(.title3)
                  if loadingComments {
                    ProgressView()
                      .controlSize(.small)
                  }
                }
                Divider()
              }
              LazyVStack(alignment: .leading, spacing: 8) {
                ForEach(Array(zip(comments.indices, comments)), id: \.1) { idx, comment in
                  CommentItemView(type: .person(personId), comment: comment, idx: idx)
                  if comment.id != comments.last?.id {
                    Divider()
                  }
                }
              }
            }
          }.padding(.horizontal, 8)
        }
        .refreshable {
          Task {
            await refresh()
          }
        }
        .sheet(isPresented: $showCommentBox) {
          CreateCommentBoxSheet(type: .person(personId)) {
            Task { await refresh() }
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
    .task {
      await loadCached()
      await refresh()
    }
    .navigationTitle(title)
    .navigationBarTitleDisplayMode(.inline)
    .toolbar {
      ToolbarItem(placement: .topBarTrailing) {
        Menu {
          Button {
            showCommentBox = true
          } label: {
            Label("吐槽", systemImage: "plus.bubble")
          }
          .disabled(!isAuthenticated)
          Divider()
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
    .handoff(url: shareLink, title: title)
    .modifier(ZoomTransitionModifier(zoomID: ZoomNavigationID(type: .person, id: personId)))
  }
}

struct PersonDetailView: View {
  let person: PersonDTO
  let detail: PersonDetailDTO
  let reload: () async -> Void

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
            .font(.footnote)
            .foregroundStyle(.secondary)
            .lineLimit(1)
          Label("\(person.comment)条评论", systemImage: "bubble")
            .font(.footnote)
            .foregroundStyle(.secondary)
            .lineLimit(1)
        }
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

#Preview {
  let container = mockContainer()

  let person = Person.preview
  container.mainContext.insert(person)

  return NavigationStack {
    PersonView(personId: person.personId)
      .modelContainer(container)
  }
}
