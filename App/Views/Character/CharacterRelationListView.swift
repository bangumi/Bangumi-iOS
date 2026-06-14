import SwiftUI

struct CharacterRelationListView: View {
  let characterId: Int

  @State private var reloader = false

  func load(limit: Int, offset: Int) async -> PagedDTO<CharacterRelationDTO>? {
    do {
      let resp = try await CharacterService.getCharacterRelations(
        characterId, limit: limit, offset: offset)
      return resp
    } catch {
      Notifier.shared.alert(error: error)
    }
    return nil
  }

  var body: some View {
    ScrollView {
      OffsetPagedView<CharacterRelationDTO, _>(reloader: reloader, nextPageFunc: load) { item in
        CharacterRelationItemView(item: item)
      }
      .padding(8)
    }
    .navigationTitle("关联角色")
    .navigationBarTitleDisplayMode(.inline)
  }
}

#Preview {
  NavigationStack {
    CharacterRelationListView(characterId: Character.preview.characterId)
  }
}
