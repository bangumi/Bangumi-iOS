import SwiftUI

struct CharacterRelationListView: View {
  let characterId: Int

  @State private var reloader = false

  func load(limit: Int, offset: Int) async -> PagedDTO<CharacterRelationListItemDTO>? {
    do {
      let resp = try await CharacterService.getCharacterRelations(
        characterId, limit: limit, offset: offset)
      guard let db = await AppContext.shared.databaseIfAvailable() else {
        return PagedDTO(
          data: resp.data.map { CharacterRelationListItemDTO(relation: $0, isCollected: false) },
          total: resp.total
        )
      }
      let statuses = try await db.characterCollectionStatuses(
        characterIds: resp.data.map { $0.character.id }
      )
      return PagedDTO(
        data: resp.data.map {
          CharacterRelationListItemDTO(
            relation: $0,
            isCollected: statuses[$0.character.id] ?? false
          )
        },
        total: resp.total
      )
    } catch {
      Notifier.shared.alert(error: error)
    }
    return nil
  }

  var body: some View {
    ScrollView {
      OffsetPagedView<CharacterRelationListItemDTO, _>(reloader: reloader, nextPageFunc: load) {
        item in
        CharacterRelationItemView(item: item.relation, isCollected: item.isCollected)
      }
      .padding(8)
    }
    .navigationTitle("关联角色")
    .navigationBarTitleDisplayMode(.inline)
  }
}
