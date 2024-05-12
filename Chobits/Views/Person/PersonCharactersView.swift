//
//  PersonCharactersView.swift
//  Chobits
//
//  Created by Chuan Chuan on 2024/5/12.
//

import SwiftData
import SwiftUI

struct PersonCharactersView: View {
  var personId: UInt

  @EnvironmentObject var notifier: Notifier
  @EnvironmentObject var chii: ChiiClient

  @Query
  private var characters: [PersonRelatedCharacter]

  @State private var refreshed: Bool = false

  init(personId: UInt) {
    self.personId = personId
    var descriptor = FetchDescriptor<PersonRelatedCharacter>(
      predicate: #Predicate<PersonRelatedCharacter> {
        $0.personId == personId
      }, sortBy: [SortDescriptor<PersonRelatedCharacter>(\.characterId, order: .reverse)])
    descriptor.fetchLimit = 5
    _characters = Query(descriptor)
  }

  func refresh() async {
    if refreshed { return }
    refreshed = true

    do {
      try await chii.loadPersonCharacters(personId)
      try await chii.db.save()
    } catch {
      notifier.alert(error: error)
    }
  }

  var body: some View {
    VStack(alignment: .leading) {
      Divider()
      if characters.count > 0 {
        HStack {
          Text("最近演出角色").font(.title3)
          Spacer()
          //        NavigationLink(value: NavDestination.personSubjectList(subjectId: 0)) {
          //          Text("更多角色 »").font(.caption).foregroundStyle(Color("LinkTextColor"))
          //        }.buttonStyle(.plain)
          Text("更多角色 »").font(.caption).foregroundStyle(Color("LinkTextColor"))
        }
      }

      ForEach(characters) { item in
        PersonCharacterItemView(personId: personId, characterId: item.characterId, subjectId: item.subjectId)
      }

      Spacer()
    }
    .animation(.default, value: characters)
    .onAppear {
      Task(priority: .background) {
        if characters.count == 0 {
          await refresh()
        }
      }
    }
  }
}

#Preview {
  let container = mockContainer()

  let person = Person.preview
  container.mainContext.insert(person)

  return ScrollView(showsIndicators: false) {
    LazyVStack(alignment: .leading) {
      PersonCharactersView(personId: person.id)
        .environmentObject(Notifier())
        .environment(ChiiClient(container: container, mock: .anime))
        .modelContainer(container)
    }.padding(.horizontal, 8)
  }
}
