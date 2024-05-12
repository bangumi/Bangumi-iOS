//
//  SubjectCharacterListView.swift
//  Chobits
//
//  Created by Chuan Chuan on 2024/5/12.
//

import SwiftData
import SwiftUI

struct SubjectCharacterListView: View {
  let subjectId: UInt

  @EnvironmentObject var notifier: Notifier
  @EnvironmentObject var chii: ChiiClient

  @Query
  private var characters: [SubjectRelatedCharacter]

  init(subjectId: UInt) {
    self.subjectId = subjectId
    let descriptor = FetchDescriptor<SubjectRelatedCharacter>(
      predicate: #Predicate<SubjectRelatedCharacter> {
        $0.subjectId == subjectId
      }, sortBy: [SortDescriptor<SubjectRelatedCharacter>(\.sort)])
    _characters = Query(descriptor)
  }

  var body: some View {
    ScrollView {
      LazyVStack(alignment: .leading) {
        ForEach(characters) { character in
          Text(character.name)
        }
      }
    }
    .padding(.horizontal, 8)
    .buttonStyle(.plain)
    .animation(.default, value: characters)
    .navigationTitle("角色列表")
    .navigationBarTitleDisplayMode(.inline)
    .toolbar {
      ToolbarItem(placement: .automatic) {
        Image(systemName: "list.bullet.circle").foregroundStyle(.secondary)
      }
    }
  }
}

#Preview {
  let container = mockContainer()

  let subject = Subject.previewAnime
  let subjectCharacters = SubjectRelatedCharacter.preview
  container.mainContext.insert(subject)
  for item in subjectCharacters {
    container.mainContext.insert(item)
  }

  return SubjectCharacterListView(subjectId: subject.id)
    .environmentObject(Notifier())
    .environment(ChiiClient(container: container, mock: .anime))
    .modelContainer(container)

}
