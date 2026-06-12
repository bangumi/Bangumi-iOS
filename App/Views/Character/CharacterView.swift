import BBCode
import OSLog
import SwiftUI

struct CharacterView: View {
  var characterId: Int

  @AppStorage("shareDomain") var shareDomain: ShareDomain = .chii
  @AppStorage("isolationMode") var isolationMode: Bool = false
  @AppStorage("isAuthenticated") var isAuthenticated: Bool = false
  @AppStorage("titlePreference") var titlePreference: TitlePreference = .original

  @State private var refreshed: Bool = false
  @State private var character: CharacterDTO?
  @State private var detail: CharacterDetailDTO = CharacterDetailDTO()
  @State private var comments: [CommentDTO] = []
  @State private var loadingComments: Bool = false
  @State private var showCommentBox: Bool = false
  @State private var showIndexPicker: Bool = false

  var shareLink: URL {
    URL(string: "\(shareDomain.url)/character/\(characterId)")!
  }

  var title: String {
    guard let character = character else {
      return "角色"
    }
    return character.title(with: titlePreference)
  }

  private func loadCached() async {
    do {
      let db = try await AppContext.shared.getDB()
      character = try await db.getCharacterDTO(characterId)
      detail = try await db.getCharacterDetailDTO(characterId)
    } catch {
      Logger.app.error("Failed to load cached character: \(error)")
    }
  }

  func refresh() async {
    do {
      try await CharacterRepository.loadCharacter(characterId)
      await loadCached()
      refreshed = true

      if !isolationMode {
        loadingComments = true
        comments = try await CharacterService.getCharacterComments(characterId)
        loadingComments = false
      }

      try await CharacterRepository.loadCharacterDetails(characterId)
      await loadCached()
    } catch {
      Notifier.shared.alert(error: error)
      return
    }
  }

  var body: some View {
    Section {
      if let character = character {
        ScrollView {
          LazyVStack(alignment: .leading) {
            CharacterDetailView(character: character, detail: detail) {
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
                  CommentItemView(type: .character(characterId), comment: comment, idx: idx)
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
          CreateCommentBoxSheet(type: .character(characterId)) {
            Task { await refresh() }
          }
        }
        .sheet(isPresented: $showIndexPicker) {
          IndexPickerSheet(
            category: .character,
            itemId: characterId,
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
    .modifier(ZoomTransitionModifier(zoomID: ZoomNavigationID(type: .character, id: characterId)))
  }
}

struct CharacterDetailView: View {
  let character: CharacterDTO
  let detail: CharacterDetailDTO
  let reload: () async -> Void

  @State private var updating: Bool = false

  func collect() async {
    updating = true
    defer { updating = false }
    do {
      if character.collectedAt ?? 0 == 0 {
        try await CharacterRepository.collectCharacter(character.id)
      } else {
        try await CharacterRepository.uncollectCharacter(character.id)
      }
      await reload()
      UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    } catch {
      Notifier.shared.alert(error: error)
    }
  }

  var body: some View {
    /// title
    Text(character.name)
      .font(.title2.bold())
      .multilineTextAlignment(.leading)

    /// header
    HStack(alignment: .top) {
      ImageView(img: character.images?.resize(.r400))
        .imageStyle(width: 120, height: 120, alignment: .top)
        .imageType(.person)
        .imageNSFW(character.nsfw)
        .enableImagePreview(
          character.images?.large,
          zoomID: ZoomNavigationID(type: .character, id: character.id)
        )
        .padding(4)
        .shadow(radius: 4)
      VStack(alignment: .leading) {
        HStack {
          Label(character.role.description, systemImage: character.role.icon)
            .font(.footnote)
            .foregroundStyle(.secondary)
          Spacer()
          Button {
            Task {
              await collect()
            }
          } label: {
            HeartView(collected: (character.collectedAt ?? 0) != 0, updating: updating)
          }
        }
        .buttonStyle(.explode)
        .padding(.trailing, 16)

        Spacer()
        if character.nameCN.isEmpty {
          Text(character.name)
            .multilineTextAlignment(.leading)
            .truncationMode(.middle)
            .lineLimit(2)
            .textSelection(.enabled)
        } else {
          Text(character.nameCN)
            .multilineTextAlignment(.leading)
            .truncationMode(.middle)
            .lineLimit(2)
            .textSelection(.enabled)
        }
        Spacer()

        NavigationLink(value: NavDestination.infobox("角色信息", character.infobox)) {
          HStack {
            Text(character.info)
              .font(.caption)
              .lineLimit(2)
            Spacer()
            Image(systemName: "chevron.right")
          }
        }
        .buttonStyle(.navigation)
        .padding(.vertical, 4)

        HStack {
          Label("\(character.collects)人收藏", systemImage: "heart")
            .font(.footnote)
            .foregroundStyle(.secondary)
            .lineLimit(1)
          Label("\(character.comment)条评论", systemImage: "bubble")
            .font(.footnote)
            .foregroundStyle(.secondary)
            .lineLimit(1)
        }
      }.padding(.leading, 2)
    }.frame(height: 120)

    /// summary
    BBCodeView(character.summary, textSize: 14)
      .textSelection(.enabled)
      .padding(2)
      .tint(.linkText)

    /// casts
    CharacterCastsView(characterId: character.id, casts: detail.casts)

    /// relations
    CharacterRelationsView(characterId: character.id, relations: detail.relations)

    /// indexes
    CharacterIndexsView(characterId: character.id, indexes: detail.indexes)
  }
}

#Preview {
  let container = mockContainer()

  let character = Character.preview
  container.mainContext.insert(character)

  return NavigationStack {
    CharacterView(characterId: character.characterId)
      .modelContainer(container)
  }
}
