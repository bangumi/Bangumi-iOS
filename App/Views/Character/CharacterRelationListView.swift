import OSLog
import SwiftUI

struct CharacterRelationListView: View {
  let characterId: Int

  @State private var reloader = false
  @State private var collectionStatuses: [Int: Bool] = [:]
  @State private var loadedCharacterIds: Set<Int> = []

  private func loadCollectionStatuses(characterIds: [Int]) async {
    guard !characterIds.isEmpty else { return }
    do {
      guard let db = await AppContext.shared.databaseIfAvailable() else { return }
      let statuses = try await db.characterCollectionStatuses(characterIds: characterIds)
      collectionStatuses.merge(statuses) { _, new in new }
    } catch {
      Logger.app.error("Failed to load character collection statuses: \(error)")
    }
  }

  private func handleMonoCollectionInvalidation(_ notification: Notification) {
    guard let characterId = MonoCollectionInvalidation.characterId(from: notification),
      loadedCharacterIds.contains(characterId)
    else {
      return
    }
    Task {
      await loadCollectionStatuses(characterIds: [characterId])
    }
  }

  func load(limit: Int, offset: Int) async -> PagedDTO<CharacterRelationDTO>? {
    do {
      let resp = try await CharacterService.getCharacterRelations(
        characterId, limit: limit, offset: offset)
      let characterIds = resp.data.map { $0.character.id }
      loadedCharacterIds.formUnion(characterIds)
      await loadCollectionStatuses(characterIds: characterIds)
      return resp
    } catch {
      Notifier.shared.alert(error: error)
    }
    return nil
  }

  var body: some View {
    ScrollView {
      OffsetPagedView<CharacterRelationDTO, _>(reloader: reloader, nextPageFunc: load) { item in
        CharacterRelationItemView(
          item: item,
          isCollected: collectionStatuses[item.character.id] ?? false
        )
      }
      .padding(8)
    }
    .onReceive(
      NotificationCenter.default.publisher(for: MonoCollectionInvalidation.notificationName),
      perform: handleMonoCollectionInvalidation
    )
    .onAppear {
      Task {
        await loadCollectionStatuses(characterIds: Array(loadedCharacterIds))
      }
    }
    .navigationTitle("关联角色")
    .navigationBarTitleDisplayMode(.inline)
  }
}
