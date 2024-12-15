//
//  CharacterSubjectsView.swift
//  Chobits
//
//  Created by Chuan Chuan on 2024/5/11.
//

import SwiftData
import SwiftUI

struct CharacterCastsView: View {
  @ObservableModel var character: Character

  @State private var loaded: Bool = false
  @State private var loading: Bool = false

  func load() {
    if loading || loaded { return }
    loading = true
    Task {
      do {
        let resp = try await Chii.shared.getCharacterCasts(character.characterId, limit: 5)
        character.casts.append(contentsOf: resp.data)
      } catch {
        Notifier.shared.alert(error: error)
      }
      loading = false
      loaded = true
    }
  }

  var body: some View {
    VStack(spacing: 2) {
      HStack(alignment: .bottom) {
        Text("出演作品")
          .foregroundStyle(character.casts.count > 0 ? .primary : .secondary)
          .font(.title3)
          .onAppear(perform: load)
        if loading {
          ProgressView()
        }
        Spacer()
        if character.casts.count > 0 {
          NavigationLink(value: NavDestination.characterCastList(character.characterId)) {
            Text("更多出演 »").font(.caption)
          }.buttonStyle(.navLink)
        }
      }
      Divider()
    }.padding(.top, 5)
    LazyVStack {
      ForEach(character.casts, id: \.subject.id) { item in
        VStack {
          CharacterCastItemView(item: item)
          Divider()
        }
      }
    }.animation(.default, value: character.casts)
  }
}

#Preview {
  let container = mockContainer()

  let character = Character.preview
  container.mainContext.insert(character)

  return ScrollView(showsIndicators: false) {
    LazyVStack(alignment: .leading) {
      CharacterCastsView(character: character)
        .modelContainer(container)
    }.padding(.horizontal, 8)
  }
}
