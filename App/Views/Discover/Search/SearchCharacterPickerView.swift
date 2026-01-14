import SwiftData
import SwiftUI

struct SearchCharacterPickerView: View {
  @Environment(\.dismiss) var dismiss

  let onSelect: (Int) -> Void

  @State private var searchText: String = ""
  @State private var searching: Bool = false
  @State private var remote: Bool = false

  var body: some View {
    NavigationStack {
      ScrollView {
        VStack {
          if searchText.isEmpty {
            Text("输入关键字搜索")
              .foregroundStyle(.secondary)
              .padding(8)
          } else {
            if remote {
              SearchCharacterPickerRemoteView(text: searchText, onSelect: onSelect)
            } else {
              SearchCharacterPickerLocalView(text: searchText, onSelect: onSelect)
            }
          }
        }.padding()
      }
      .animation(.default, value: searchText)
      .animation(.default, value: remote)
      .navigationTitle("搜索角色")
      .navigationBarTitleDisplayMode(.inline)
      .searchable(text: $searchText, isPresented: $searching, prompt: "搜索角色")
      .searchPresentationToolbarBehavior(.avoidHidingContent)
      .onSubmit(of: .search) {
        remote = true
      }
      .onChange(of: searchText) { _, _ in
        remote = false
      }
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button {
            dismiss()
          } label: {
            Label("取消", systemImage: "xmark")
          }
        }
        ToolbarItem(placement: .confirmationAction) {
          Image(systemName: remote ? "globe" : "internaldrive")
            .foregroundColor(remote ? .blue : .green)
        }
      }
    }
  }
}

struct SearchCharacterPickerRemoteView: View {
  let text: String
  let onSelect: (Int) -> Void

  @Environment(\.dismiss) var dismiss

  private func fetch(limit: Int, offset: Int) async -> PagedDTO<SlimCharacterDTO>? {
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
      SearchCharacterPickerItemView(characterId: item.id) { selectedId in
        onSelect(selectedId)
        dismiss()
      }
    }
  }
}

struct SearchCharacterPickerLocalView: View {
  let text: String
  let onSelect: (Int) -> Void

  @Environment(\.dismiss) var dismiss
  @Query private var characters: [Character]

  init(text: String, onSelect: @escaping (Int) -> Void) {
    self.text = text.gb
    self.onSelect = onSelect

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
        .onTapGesture {
          onSelect(character.characterId)
          dismiss()
        }
      }
    }
  }
}

struct SearchCharacterPickerItemView: View {
  let characterId: Int
  let onSelect: (Int) -> Void

  @Query private var characters: [Character]
  private var character: Character? { characters.first }

  init(characterId: Int, onSelect: @escaping (Int) -> Void) {
    self.characterId = characterId
    self.onSelect = onSelect

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
    .onTapGesture {
      onSelect(characterId)
    }
  }
}
