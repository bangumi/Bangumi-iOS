//
//  CharacterSubjectsView.swift
//  Chobits
//
//  Created by Chuan Chuan on 2024/5/11.
//

import SwiftData
import SwiftUI

struct CharacterCastsView: View {
  var characterId: Int

  @State private var loaded: Bool = false
  @State private var loading: Bool = false
  @State private var casts: [CharacterCastDTO] = []

  func load() {
    if loading || loaded { return }
    loading = true
    Task {
      do {
        let resp = try await Chii.shared.getCharacterCasts(characterId, limit: 5)
        casts.append(contentsOf: resp.data)
      } catch {
        Notifier.shared.alert(error: error)
      }
      loading = false
      loaded = true
    }
  }

  var body: some View {
    Divider()
    HStack {
      Text("出演作品")
        .foregroundStyle(casts.count > 0 ? .primary : .secondary)
        .font(.title3)
        .onAppear(perform: load)
      if loading {
        ProgressView()
      }
      Spacer()
      if casts.count > 0 {
        NavigationLink(value: NavDestination.characterCastList(characterId: characterId)) {
          Text("更多出演 »").font(.caption).foregroundStyle(.linkText)
        }.buttonStyle(.plain)
      }
    }
    LazyVStack {
      ForEach(casts, id: \.subject.id) { item in
        VStack {
          CharacterCastItemView(item: item)
          Divider()
        }
      }
    }.animation(.default, value: casts)
  }
}

#Preview {
  let container = mockContainer()

  let character = Character.preview
  container.mainContext.insert(character)
  container.mainContext.insert(Subject.previewAnime)
  container.mainContext.insert(Subject.previewBook)

  return ScrollView(showsIndicators: false) {
    LazyVStack(alignment: .leading) {
      CharacterCastsView(characterId: character.characterId)
        .modelContainer(container)
    }.padding(.horizontal, 8)
  }
}
