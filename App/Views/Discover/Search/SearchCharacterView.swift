import OSLog
import SwiftUI

struct SearchCharacterView: View {
  let text: String

  func fetch(limit: Int, offset: Int) async -> PagedDTO<SlimCharacterDTO>? {
    do {
      guard let db = await AppContext.shared.databaseIfAvailable() else {
        throw ChiiError.uninitialized
      }
      let resp = try await SearchService.searchCharacters(
        keyword: text.gb, limit: limit, offset: offset)
      for item in resp.data {
        try await db.saveCharacter(item)
      }
      return resp
    } catch {
      Notifier.shared.alert(error: error)
    }
    return nil
  }

  var body: some View {
    OffsetPagedView<SlimCharacterDTO, _>(nextPageFunc: fetch) { item in
      SearchCharacterItemView(characterId: item.id)
    }
  }
}

struct SearchCharacterItemView: View {
  let characterId: Int

  @State private var character: CharacterDTO?

  private func load() async {
    do {
      let db = try await AppContext.shared.getDB()
      character = try await db.getCharacterDTO(characterId)
    } catch {
      Notifier.shared.alert(error: error)
    }
  }

  private func handleMonoCollectionInvalidation(_ notification: Notification) {
    guard MonoCollectionInvalidation.characterId(from: notification) == characterId else {
      return
    }
    Task {
      await load()
    }
  }

  var body: some View {
    CardView {
      if let character = character {
        CharacterLargeRowView(character: character)
      }
    }
    .task(id: characterId) {
      await load()
    }
    .onReceive(
      NotificationCenter.default.publisher(for: MonoCollectionInvalidation.notificationName),
      perform: handleMonoCollectionInvalidation
    )
    .onAppear {
      Task {
        await load()
      }
    }
  }
}

struct SearchCharacterLocalView: View {
  let text: String

  @State private var characters: [CharacterDTO] = []

  private func load() async {
    do {
      let db = try await AppContext.shared.getDB()
      characters = try await db.fetchLocalCharacters(search: text.gb)
    } catch {
      Notifier.shared.alert(error: error)
    }
  }

  private func handleMonoCollectionInvalidation(_ notification: Notification) {
    guard let characterId = MonoCollectionInvalidation.characterId(from: notification),
      characters.contains(where: { $0.id == characterId })
    else {
      return
    }
    Task {
      await load()
    }
  }

  var body: some View {
    LazyVStack {
      ForEach(characters) { character in
        CardView {
          CharacterLargeRowView(character: character)
        }
      }
    }
    .task(id: text) {
      await load()
    }
    .onReceive(
      NotificationCenter.default.publisher(for: MonoCollectionInvalidation.notificationName),
      perform: handleMonoCollectionInvalidation
    )
    .onAppear {
      Task {
        await load()
      }
    }
  }
}
