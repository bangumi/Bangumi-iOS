import Flow
import SwiftData
import SwiftUI

struct CharacterCastListView: View {
  let characterId: Int

  @State private var type: CastType = .none
  @State private var reloader = false

  func load(limit: Int, offset: Int) async -> PagedDTO<CharacterCastDTO>? {
    do {
      let resp = try await Chii.shared.getCharacterCasts(
        characterId, type: type, limit: limit, offset: offset)
      return resp
    } catch {
      Notifier.shared.alert(error: error)
    }
    return nil
  }

  var body: some View {
    Picker("Cast Type", selection: $type) {
      ForEach(CastType.allCases) { ct in
        Text(ct.description).tag(ct)
      }
    }
    .padding(.horizontal, 8)
    .pickerStyle(.segmented)
    .onChange(of: type) { _, _ in
      reloader.toggle()
    }
    ScrollView {
      PageView<CharacterCastDTO, _>(reloader: reloader, nextPageFunc: load) { item in
        CharacterCastItemView(item: item)
      }
      .padding(8)
    }
    .buttonStyle(.navigation)
    .navigationTitle("出演作品")
    .navigationBarTitleDisplayMode(.inline)
  }
}

#Preview {
  let character = Character.preview
  return CharacterCastListView(characterId: character.characterId)
}
