import BBCode
import OSLog
import SwiftData
import SwiftUI

struct CharacterView: View {
  var characterId: Int

  @AppStorage("shareDomain") var shareDomain: ShareDomain = .chii
  @AppStorage("isolationMode") var isolationMode: Bool = false

  @State private var refreshed: Bool = false

  @Query private var characters: [Character]
  private var character: Character? { characters.first }

  @State private var comments: [CommentDTO] = []
  @State private var loadingComments: Bool = false
  @State private var showCommentBox: Bool = false

  init(characterId: Int) {
    self.characterId = characterId
    let predicate = #Predicate<Character> {
      $0.characterId == characterId
    }
    _characters = Query(filter: predicate, sort: \Character.characterId)
  }

  var shareLink: URL {
    URL(string: "\(shareDomain.url)/character/\(characterId)")!
  }

  var title: String {
    guard let character = character else {
      return "角色"
    }
    return character.name
  }

  func refresh() async {
    do {
      try await Chii.shared.loadCharacter(characterId)
      refreshed = true

      if !isolationMode {
        loadingComments = true
        comments = try await Chii.shared.getCharacterComments(characterId)
        loadingComments = false
      }

      try await Chii.shared.loadCharacterDetails(characterId)
    } catch {
      Notifier.shared.alert(error: error)
      return
    }
  }

  var body: some View {
    Section {
      if let character = character {
        ScrollView {
          VStack(alignment: .leading) {
            CharacterDetailView()
              .environment(character)

            /// comments
            if !isolationMode {
              VStack(alignment: .leading, spacing: 2) {
                Text("吐槽箱").font(.title3)
                if loadingComments {
                  HStack {
                    ProgressView()
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
          CreateCommentBoxView(type: .character(characterId))
            .presentationDetents([.large])
        }
      } else if refreshed {
        NotFoundView()
      } else {
        ProgressView()
      }
    }
    .task(refresh)
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
          Divider()
          ShareLink(item: shareLink) {
            Label("分享", systemImage: "square.and.arrow.up")
          }
        } label: {
          Image(systemName: "ellipsis.circle")
        }
      }
    }
  }
}

struct CharacterDetailView: View {
  @Environment(Character.self) var character

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
        .enableSave(character.images?.large)
        .padding(4)
        .shadow(radius: 4)
      VStack(alignment: .leading) {
        HStack {
          Label(character.roleEnum.description, systemImage: character.roleEnum.icon)
          Spacer()
        }
        .font(.footnote)
        .foregroundStyle(.secondary)

        Spacer()
        Text(character.title)
          .multilineTextAlignment(.leading)
          .truncationMode(.middle)
          .lineLimit(2)
          .textSelection(.enabled)
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

        Label("\(character.collects)人收藏", systemImage: "heart")
          .font(.footnote)
          .foregroundStyle(.secondary)
          .lineLimit(1)

        Label("\(character.comment)条评论", systemImage: "bubble")
          .font(.footnote)
          .foregroundStyle(.secondary)
          .lineLimit(1)
      }.padding(.leading, 2)
    }.frame(height: 120)

    /// summary
    BBCodeView(character.summary, textSize: 14)
      .textSelection(.enabled)
      .padding(2)
      .tint(.linkText)

    /// casts
    CharacterCastsView(characterId: character.characterId, casts: character.casts)
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
