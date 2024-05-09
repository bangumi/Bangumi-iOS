//
//  SubjectCharactersView.swift
//  Chobits
//
//  Created by Chuan Chuan on 2024/5/9.
//

import SwiftData
import SwiftUI

struct SubjectCharactersView: View {
  let subjectId: UInt

  @EnvironmentObject var notifier: Notifier
  @EnvironmentObject var chii: ChiiClient

  @State private var refreshed: Bool = false

  @Query
  private var characters: [SubjectRelatedCharacter]

  init(subjectId: UInt) {
    self.subjectId = subjectId
    _characters = Query(
      filter: #Predicate<SubjectRelatedCharacter> {
        $0.subjectId == subjectId
      })
  }

  func refresh() async {
    if refreshed { return }
    refreshed = true

    do {
      try await chii.loadSubjectCharacters(subjectId)
      try await chii.db.save()
    } catch {
      notifier.alert(error: error)
    }
  }

  var body: some View {
    VStack {
      Text("角色介绍").font(.title3)
    }.onAppear {
      Task(priority: .background) {
        await refresh()
      }
    }
    ScrollView(.horizontal) {
      HStack {
        ForEach(characters) { character in
          Text(character.name)
        }
      }
    }
  }
}

#Preview {
  let container = mockContainer()

  let subject = Subject.previewAnime

  return ScrollView {
    LazyVStack(alignment: .leading) {
      SubjectCharactersView(subjectId: subject.id)
        .environmentObject(Notifier())
        .environment(ChiiClient(container: container, mock: .anime))
        .modelContainer(container)
    }
  }.padding()
}
