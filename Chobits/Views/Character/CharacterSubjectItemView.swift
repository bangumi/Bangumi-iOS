//
//  CharacterSubjectItemView.swift
//  Chobits
//
//  Created by Chuan Chuan on 2024/5/12.
//

import SwiftData
import SwiftUI

struct CharacterSubjectItemView: View {
  var characterId: UInt
  var subjectId: UInt

  @Environment(Notifier.self) private var notifier

  @Query
  private var relations: [CharacterRelatedSubject]
  private var relation: CharacterRelatedSubject? { relations.first }

  @Query
  private var subjects: [Subject]
  private var subject: Subject? { subjects.first }

  @Query
  private var persons: [CharacterRelatedPerson]
  private var person: CharacterRelatedPerson? { persons.first }

  init(characterId: UInt, subjectId: UInt) {
    self.characterId = characterId
    self.subjectId = subjectId

    var relationDescriptor = FetchDescriptor<CharacterRelatedSubject>(
      predicate: #Predicate<CharacterRelatedSubject> {
        $0.characterId == characterId
          && $0.subjectId == subjectId
      }, sortBy: [SortDescriptor<CharacterRelatedSubject>(\.subjectId)])
    relationDescriptor.fetchLimit = 1
    _relations = Query(relationDescriptor)

    var subjectDescriptor = FetchDescriptor<Subject>(
      predicate: #Predicate<Subject> {
        $0.subjectId == subjectId
      }, sortBy: [SortDescriptor<Subject>(\Subject.subjectId)])
    subjectDescriptor.fetchLimit = 1
    _subjects = Query(subjectDescriptor)

    var personDescriptor = FetchDescriptor<CharacterRelatedPerson>(
      predicate: #Predicate<CharacterRelatedPerson> {
        $0.characterId == characterId
          && $0.subjectId == subjectId
      }, sortBy: [SortDescriptor<CharacterRelatedPerson>(\.personId)])
    personDescriptor.fetchLimit = 1
    _persons = Query(personDescriptor)
  }

  var body: some View {
    if let subject = subject {
      HStack(alignment: .bottom) {
        NavigationLink(value: NavDestination.subject(subjectId: subjectId)) {
          ImageView(img: subject.images.common, width: 60, height: 60, type: .subject)
          VStack(alignment: .leading) {
            HStack {
              if !subject.typeEnum.icon.isEmpty {
                Image(systemName: subject.typeEnum.icon)
                  .font(.footnote)
                  .foregroundStyle(.secondary)
              }
              Text(subject.name)
                .foregroundStyle(Color("LinkTextColor"))
                .lineLimit(1)
            }.padding(.bottom, 2)
            HStack(alignment: .bottom) {
              if let relation = relation {
                Text(relation.staff)
                  .font(.footnote)
                  .foregroundStyle(.secondary)
                  .overlay {
                    RoundedRectangle(cornerRadius: 4)
                      .stroke(Color.secondary, lineWidth: 1)
                      .padding(.horizontal, -2)
                      .padding(.vertical, -1)
                  }
              }
              Text(subject.nameCn)
                .font(.footnote)
                .lineLimit(1)
                .foregroundStyle(.secondary)
            }
          }
        }.buttonStyle(.plain)
        Spacer()
        if let person = person {
          NavigationLink(value: NavDestination.person(personId: person.personId)) {
            HStack(alignment: .bottom) {
              VStack(alignment: .trailing) {
                Text("CV")
                  .font(.caption)
                  .foregroundStyle(.secondary)
                Text(person.name)
                  .font(.footnote)
                  .foregroundStyle(Color("LinkTextColor"))
              }
              ImageView(img: person.images.grid, width: 40, height: 40, alignment: .top)
            }
          }.buttonStyle(.plain)
        }
      }
      Divider()
    }
  }
}

#Preview {
  let container = mockContainer()

  let character = Character.preview
  let subject = Subject.previewAnime
  let characterSubjects = CharacterRelatedSubject.preview
  let characterPersons = CharacterRelatedPerson.preview
  container.mainContext.insert(character)
  container.mainContext.insert(subject)
  for item in characterSubjects {
    container.mainContext.insert(item)
  }
  for item in characterPersons {
    container.mainContext.insert(item)
  }

  return ScrollView(showsIndicators: false) {
    LazyVStack(alignment: .leading) {
      CharacterSubjectItemView(characterId: character.characterId, subjectId: subject.subjectId)
        .environment(Notifier())
        .modelContainer(container)
    }.padding(.horizontal, 8)
  }
}
