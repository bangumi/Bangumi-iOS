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

  @Environment(Notifier.self) private var notifier

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
      try await Chii.shared.loadPersonCharacters(personId)
    } catch {
      notifier.alert(error: error)
    }
  }

  var body: some View {
    VStack(alignment: .leading) {
      if characters.count > 0 {
        Divider()
        HStack {
          Text("最近演出角色").font(.title3)
          Spacer()
          NavigationLink(value: NavDestination.personCharacterList(personId: personId)) {
            Text("更多角色 »").font(.caption).foregroundStyle(.linkText)
          }.buttonStyle(.plain)
        }
      } else if !refreshed {
        ProgressView()
          .onAppear {
            Task {
              await refresh()
            }
          }
      }

      ForEach(characters) { item in
        PersonCharacterItemView(
          personId: personId, characterId: item.characterId, subjectId: item.subjectId)
      }
    }.animation(.default, value: characters)
  }
}

#Preview {
  let container = mockContainer()

  let person = Person.preview
  container.mainContext.insert(person)

  return ScrollView(showsIndicators: false) {
    LazyVStack(alignment: .leading) {
      PersonCharactersView(personId: person.personId)
        .environment(Notifier())
        .modelContainer(container)
    }.padding(.horizontal, 8)
  }
}
