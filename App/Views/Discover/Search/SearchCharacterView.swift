import OSLog
import SwiftData
import SwiftUI

struct SearchCharacterView: View {
  let text: String

  func fetch(limit: Int, offset: Int) async -> PagedDTO<SlimCharacterDTO>? {
    do {
      guard let db = await Chii.shared.db else {
        throw ChiiError.uninitialized
      }
      let resp = try await Chii.shared.searchCharacters(
        keyword: text.gb, limit: limit, offset: offset)
      for item in resp.data {
        try await db.saveCharacter(item)
      }
      await db.commit()
      return resp
    } catch {
      Notifier.shared.alert(error: error)
    }
    return nil
  }

  var body: some View {
    PageView<SlimCharacterDTO, _>(nextPageFunc: fetch) { item in
      SearchCharacterItemView(characterId: item.id)
    }
  }
}

struct SearchCharacterItemView: View {
  let characterId: Int

  @Query private var characters: [Character]
  private var character: Character? { characters.first }

  init(characterId: Int) {
    self.characterId = characterId

    let desc = FetchDescriptor<Character>(
      predicate: #Predicate<Character> {
        return $0.characterId == characterId
      }
    )
    _characters = Query(desc)
  }

  var body: some View {
    CardView {
      if let character = character {
        CharacterLargeRowView(character: character)
      }
    }
  }
}

struct SearchCharacterLocalView: View {
  let text: String

  @Query private var characters: [Character]

  init(text: String) {
    self.text = text.gb

    var desc = FetchDescriptor<Character>(
      predicate: #Predicate<Character> {
        return $0.name.localizedStandardContains(text)
          || $0.alias.localizedStandardContains(text)
      })
    desc.fetchLimit = 20
    _characters = Query(desc)
  }

  var body: some View {
    LazyVStack {
      ForEach(characters) { character in
        CardView {
          CharacterLargeRowView(character: character)
        }
      }
    }
  }
}
