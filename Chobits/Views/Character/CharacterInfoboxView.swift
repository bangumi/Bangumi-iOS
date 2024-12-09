//
//  CharacterInfoboxView.swift
//  Chobits
//
//  Created by Chuan Chuan on 2024/5/9.
//

import Flow
import SwiftData
import SwiftUI

struct CharacterInfoboxView: View {
  @ObservableModel var character: Character

  var body: some View {
    ScrollView {
      InfoboxView(infobox: character.infobox)
        .navigationTitle("角色信息")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
          ToolbarItem(placement: .automatic) {
            Image(systemName: "info.circle").foregroundStyle(.secondary)
          }
        }
    }
  }
}

#Preview {
  let container = mockContainer()

  let character = Character.preview
  container.mainContext.insert(character)

  return CharacterInfoboxView(character: character)
    .modelContainer(container)
}
