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
      .searchInputTraits()
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
        .onTapGesture {
          onSelect(character.id)
          dismiss()
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

struct SearchCharacterPickerItemView: View {
  let characterId: Int
  let onSelect: (Int) -> Void

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
    .onTapGesture {
      onSelect(characterId)
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
