//
//  PersonCharacterListView.swift
//  Chobits
//
//  Created by Chuan Chuan on 2024/5/13.
//

import SwiftData
import SwiftUI

struct PersonCharacterListView: View {
  let personId: UInt

  @Environment(Notifier.self) private var notifier
  @Environment(\.modelContext) var modelContext

  @State private var relationType: SubjectCharacterRelationType = .unknown
  @State private var characterIds: [UInt] = []

  func load() async {
    let rtype = relationType.description
    let allType = SubjectCharacterRelationType.unknown.description
    let descriptor = FetchDescriptor<PersonRelatedCharacter>(
      predicate: #Predicate<PersonRelatedCharacter> {
        if rtype == allType {
          return $0.personId == personId
        } else {
          return $0.personId == personId && $0.staff == rtype
        }
      },
      sortBy: [
        SortDescriptor<PersonRelatedCharacter>(\.characterId, order: .reverse),
        SortDescriptor<PersonRelatedCharacter>(\.subjectId, order: .reverse),
      ])
    do {
      let characters = try modelContext.fetch(descriptor)
      let chars = Dictionary(grouping: characters, by: { $0.characterId })
      characterIds = chars.keys.sorted()
    } catch {
      notifier.alert(error: error)
    }
  }

  var body: some View {
    Picker("Relation Type", selection: $relationType) {
      ForEach(SubjectCharacterRelationType.allCases) { type in
        Text(type.description).tag(type)
      }
    }
    .padding(.horizontal, 8)
    .pickerStyle(.segmented)
    .onAppear {
      Task {
        await load()
      }
    }
    .onChange(of: relationType) { _, _ in
      Task {
        await load()
      }
    }
    ScrollView {
      LazyVStack(alignment: .leading) {
        ForEach(characterIds, id: \.self) { cid in
          PersonCharacterListItemView(characterId: cid)
          Divider()
        }
      }.padding(.horizontal, 8)
    }
    .buttonStyle(.plain)
    .animation(.default, value: characterIds)
    .navigationTitle("出演角色")
    .navigationBarTitleDisplayMode(.inline)
    .toolbar {
      ToolbarItem(placement: .automatic) {
        Image(systemName: "list.bullet.circle").foregroundStyle(.secondary)
      }
    }
  }
}

struct PersonCharacterListItemView: View {
  let characterId: UInt

  @Environment(Notifier.self) private var notifier
  @Environment(\.modelContext) var modelContext

  @State private var character: Character? = nil
  @State private var relations: [PersonRelatedCharacter] = []

  func load() async {
    do {
      var cdesc = FetchDescriptor<Character>(
        predicate: #Predicate<Character> {
          $0.characterId == characterId
        })
      cdesc.fetchLimit = 1
      let characters = try modelContext.fetch(cdesc)
      if let c = characters.first {
        character = c
      }

      let rdesc = FetchDescriptor<PersonRelatedCharacter>(
        predicate: #Predicate<PersonRelatedCharacter> {
          $0.characterId == characterId
        }, sortBy: [SortDescriptor<PersonRelatedCharacter>(\.subjectId, order: .reverse)])
      relations = try modelContext.fetch(rdesc)
    } catch {
      notifier.alert(error: error)
    }
  }
  var body: some View {
    HStack(alignment: .top) {
      if let character = character {
        NavigationLink(value: NavDestination.character(characterId: character.characterId)) {
          ImageView(img: character.images.medium, width: 60, height: 60, alignment: .top)
          VStack(alignment: .leading) {
            HStack {
              Text(character.name)
                .foregroundStyle(.linkText)
                .lineLimit(1)
            }
          }
        }.buttonStyle(.plain)
      }
      Spacer()
      VStack(alignment: .trailing) {
        ForEach(relations) { relation in
          NavigationLink(value: NavDestination.subject(subjectId: relation.subjectId)) {
            PersonCharacterListItemSubjectItemView(
              subjectId: relation.subjectId, staff: relation.staff)
          }
          .padding(.vertical, 2)
          .buttonStyle(.plain)
        }
      }
    }
    .onAppear {
      Task {
        await load()
      }
    }
  }
}

struct PersonCharacterListItemSubjectItemView: View {
  let subjectId: UInt
  let staff: String

  @Environment(Notifier.self) private var notifier
  @Environment(\.modelContext) var modelContext

  @State private var subject: Subject? = nil

  func load() async {
    do {
      var desc = FetchDescriptor<Subject>(
        predicate: #Predicate<Subject> {
          $0.subjectId == subjectId
        })
      desc.fetchLimit = 1
      let subjects = try modelContext.fetch(desc)
      if let s = subjects.first {
        subject = s
      }
    } catch {
      notifier.alert(error: error)
    }
  }
  var body: some View {
    HStack(alignment: .bottom) {
      VStack(alignment: .trailing) {
        HStack(alignment: .bottom) {
          Text(subject?.name ?? "")
            .foregroundStyle(.linkText)
            .truncationMode(.middle)
            .lineLimit(1)
          if let icon = subject?.typeEnum.icon {
            Image(systemName: icon).foregroundStyle(.secondary)
          }
        }
        .font(.footnote)
        .padding(.bottom, 2)
        HStack(alignment: .bottom) {
          Text(subject?.nameCn ?? "")
            .truncationMode(.middle)
            .foregroundStyle(.secondary)
            .lineLimit(1)
          BorderView(.secondary, padding: 2) {
            Text(staff)
              .foregroundStyle(.secondary)
          }
        }.font(.caption)
          .padding(.trailing, 2)
      }
      ImageView(img: subject?.images.small, width: 40, height: 40, type: .subject)
    }
    .onAppear {
      Task {
        await load()
      }
    }
  }
}

#Preview {
  let container = mockContainer()

  let person = Person.preview
  let personCharacters = PersonRelatedCharacter.preview
  container.mainContext.insert(person)
  for item in personCharacters {
    container.mainContext.insert(item)
  }
  let characters = PersonRelatedCharacter.previewCharacters
  for item in characters {
    container.mainContext.insert(item)
  }
  let subjects = PersonRelatedCharacter.previewSubjects
  for item in subjects {
    container.mainContext.insert(item)
  }

  return PersonCharacterListView(personId: person.personId)
    .environment(Notifier())
    .modelContainer(container)
}
