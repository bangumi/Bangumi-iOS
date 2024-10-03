//
//  CharacterSubjectsView.swift
//  Chobits
//
//  Created by Chuan Chuan on 2024/5/11.
//

import SwiftData
import SwiftUI

struct CharacterSubjectsView: View {
  var characterId: UInt

  @Environment(Notifier.self) private var notifier
  @Environment(ChiiClient.self) private var chii

  @Query
  private var subjects: [CharacterRelatedSubject]

  @State private var refreshed: Bool = false

  init(characterId: UInt) {
    self.characterId = characterId
    let descriptor = FetchDescriptor<CharacterRelatedSubject>(
      predicate: #Predicate<CharacterRelatedSubject> {
        $0.characterId == characterId
      }, sortBy: [SortDescriptor<CharacterRelatedSubject>(\.subjectId)])
    _subjects = Query(descriptor)
  }

  func refresh() async {
    if refreshed { return }
    refreshed = true

    do {
      try await chii.loadCharacterSubjects(characterId)
      try await chii.loadCharacterPersons(characterId)
      try await chii.db.save()
    } catch {
      notifier.alert(error: error)
    }
  }

  var body: some View {
    VStack(alignment: .leading) {
      if subjects.count > 0 {
        Divider()
        Text("出演").font(.title3)
      } else if !refreshed {
        ProgressView()
          .onAppear {
            Task(priority: .background) {
              await refresh()
            }
          }
      }
      ForEach(subjects) { item in
        CharacterSubjectItemView(characterId: characterId, subjectId: item.subjectId)
      }
    }.animation(.default, value: subjects)
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
      CharacterSubjectsView(characterId: character.characterId)
        .environment(Notifier())
        .environment(ChiiClient(modelContainer: container, mock: .anime))
        .modelContainer(container)
    }.padding(.horizontal, 8)
  }
}
