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

  init(characterId: Int) {
    self.characterId = characterId
    let predicate = #Predicate<Character> {
      $0.characterId == characterId
    }
    _characters = Query(filter: predicate, sort: \Character.characterId)
  }

  var shareLink: URL {
    URL(string: "https://\(shareDomain)/character/\(characterId)")!
  }

  var nameCN: String {
    guard let character = character else {
      return ""
    }
    if character.nameCN.isEmpty {
      return character.name
    }
    return character.nameCN
  }

  func refresh() async {
    if refreshed { return }
    do {
      try await Chii.shared.loadCharacter(characterId)

      Task {
        let respCasts = try await Chii.shared.getCharacterCasts(characterId, limit: 5)
        character?.casts = respCasts.data
      }

    } catch {
      Notifier.shared.alert(error: error)
      return
    }
    refreshed = true
  }

  var body: some View {
    Section {
      if let character = character {
        ScrollView(showsIndicators: false) {
          LazyVStack(alignment: .leading) {

            /// title
            Text(character.name)
              .font(.title2.bold())
              .multilineTextAlignment(.leading)

            /// header
            HStack(alignment: .top) {
              ImageView(img: character.images?.large, large: character.images?.resize(.r400)) {
                if character.nsfw {
                  NSFWBadgeView()
                }
              }
              .imageStyle(width: 120, height: 160, alignment: .top)
              .imageType(.person)
              .padding(4)
              .shadow(radius: 4)
              VStack(alignment: .leading) {
                HStack {
                  Image(systemName: character.roleEnum.icon)
                  if character.collects > 0 {
                    Text("(\(character.collects)人收藏)").lineLimit(1)
                  }
                  Spacer()
                  if !isolationMode {
                    Label("评论: \(character.comment)", systemImage: "bubble")
                      .lineLimit(1)
                      .font(.footnote)
                  }
                }
                .font(.footnote)
                .foregroundStyle(.secondary)

                Spacer()
                Text(nameCN)
                  .multilineTextAlignment(.leading)
                  .truncationMode(.middle)
                  .lineLimit(2)
                  .textSelection(.enabled)
                Spacer()

                NavigationLink(value: NavDestination.infobox("角色信息", character.infobox)) {
                  InfoboxHeaderView(infobox: character.infobox)
                }.buttonStyle(.plain)

              }.padding(.leading, 2)
            }.frame(height: 160)

            /// summary
            BBCodeView(character.summary, textSize: 14).padding(2)

            /// casts
            CharacterCastsView(characterId: characterId, casts: character.casts)
          }.padding(.horizontal, 8)
        }
      } else {
        if refreshed {
          NotFoundView()
        } else {
          ProgressView()
        }
      }
    }
    .toolbar {
      ToolbarItem(placement: .topBarTrailing) {
        Menu {
          ShareLink(item: shareLink) {
            Label("分享", systemImage: "square.and.arrow.up")
          }
        } label: {
          Image(systemName: "ellipsis.circle")
        }
      }
    }
    .navigationTitle(character?.name ?? "角色")
    .navigationBarTitleDisplayMode(.inline)
    .onAppear {
      Task {
        await refresh()
      }
    }
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
