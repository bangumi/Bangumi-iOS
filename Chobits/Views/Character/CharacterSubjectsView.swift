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

  @EnvironmentObject var notifier: Notifier
  @EnvironmentObject var chii: ChiiClient

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
      Divider()
      Text("出演").font(.title3)

      ForEach(subjects) { item in
        CharacterSubjectItemView(characterId: characterId, subjectId: item.subjectId)
      }

      Spacer()
    }
    .animation(.default, value: subjects)
    .onAppear {
      Task(priority: .background) {
        if subjects.count == 0 {
          await refresh()
        }
      }
    }
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
      CharacterSubjectsView(characterId: character.id)
        .environmentObject(Notifier())
        .environment(ChiiClient(container: container, mock: .anime))
        .modelContainer(container)
    }.padding(.horizontal, 8)
  }
}
