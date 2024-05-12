//
//  PersonCharacterItemView.swift
//  Chobits
//
//  Created by Chuan Chuan on 2024/5/12.
//

import SwiftData
import SwiftUI

struct PersonCharacterItemView: View {
  var personId: UInt
  var characterId: UInt
  var subjectId: UInt

  @EnvironmentObject var notifier: Notifier
  @EnvironmentObject var chii: ChiiClient

  @Query
  private var characters: [PersonRelatedCharacter]
  private var character: PersonRelatedCharacter? { characters.first }

  @Query
  private var subjects: [Subject]
  private var subject: Subject? { subjects.first }

  init(personId: UInt, characterId: UInt, subjectId: UInt) {
    self.personId = personId
    self.characterId = characterId
    self.subjectId = subjectId

    var characterDescriptor = FetchDescriptor<PersonRelatedCharacter>(
      predicate: #Predicate<PersonRelatedCharacter> {
        $0.personId == personId && $0.characterId == characterId
      }, sortBy: [SortDescriptor<PersonRelatedCharacter>(\.characterId)])
    characterDescriptor.fetchLimit = 1
    _characters = Query(characterDescriptor)

    var subjectDescriptor = FetchDescriptor<Subject>(
      predicate: #Predicate<Subject> {
        $0.id == subjectId
      }, sortBy: [SortDescriptor<Subject>(\.id)])
    subjectDescriptor.fetchLimit = 1
    _subjects = Query(subjectDescriptor)
  }

  var body: some View {
    if let character = character {
      HStack(alignment: .bottom) {
        NavigationLink(value: NavDestination.character(characterId: characterId)) {
          ImageView(img: character.images.medium, width: 60, height: 60, alignment: .top)
          VStack(alignment: .leading) {
            Text(character.name)
              .foregroundStyle(Color("LinkTextColor"))
              .lineLimit(1)
            Text(character.staff)
              .font(.footnote)
              .foregroundStyle(.secondary)
              .overlay {
                RoundedRectangle(cornerRadius: 4)
                  .stroke(Color.secondary, lineWidth: 1)
                  .padding(.horizontal, -2)
                  .padding(.vertical, -1)
              }
          }
        }.buttonStyle(.plain)
        Spacer()
        if let subject = subject {
          NavigationLink(value: NavDestination.subject(subjectId: subjectId)) {
            HStack(alignment: .bottom) {
              VStack(alignment: .trailing) {
                Text(subject.nameCn)
                  .font(.caption)
                  .foregroundStyle(.secondary)
                  .lineLimit(1)
                Text(subject.name)
                  .font(.footnote)
                  .foregroundStyle(Color("LinkTextColor"))
                  .lineLimit(1)
              }
              ImageView(img: subject.images.common, width: 40, height: 40, type: .subject)
            }
          }.buttonStyle(.plain)
        }
      }
    }
  }
}

#Preview {
  let container = mockContainer()

  let person = Person.preview
  let character = Character.preview
  let subject = Subject.previewAnime
  let personCharacters = PersonRelatedCharacter.preview
  let personSubjects = PersonRelatedSubject.preview
  container.mainContext.insert(person)
  container.mainContext.insert(character)
  container.mainContext.insert(subject)
  for item in personCharacters {
    container.mainContext.insert(item)
  }
  for item in personSubjects {
    container.mainContext.insert(item)
  }

  return ScrollView(showsIndicators: false) {
    LazyVStack(alignment: .leading) {
      PersonCharacterItemView(personId: person.id, characterId: character.id, subjectId: subject.id)
        .environmentObject(Notifier())
        .environment(ChiiClient(container: container, mock: .anime))
        .modelContainer(container)
    }.padding(.horizontal, 8)
  }
}
