import SwiftUI

struct CharacterIndexListView: View {
  let characterId: Int

  @State private var reloader = false

  func load(limit: Int, offset: Int) async -> PagedDTO<SlimIndexDTO>? {
    do {
      let resp = try await Chii.shared.getCharacterIndexes(
        characterId: characterId, limit: limit, offset: offset)
      return resp
    } catch {
      Notifier.shared.alert(error: error)
    }
    return nil
  }

  var body: some View {
    ScrollView {
      PageView<SlimIndexDTO, _>(reloader: reloader, nextPageFunc: load) { item in
        CardView {
          IndexItemView(index: item)
        }
      }.padding(8)
    }
    .navigationTitle("相关目录")
    .navigationBarTitleDisplayMode(.inline)
  }
}

#Preview {
  NavigationStack {
    CharacterIndexListView(characterId: 1)
  }
}
