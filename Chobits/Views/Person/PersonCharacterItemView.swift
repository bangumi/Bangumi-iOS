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
  @Environment(\.modelContext) var modelContext

  @State private var character: PersonRelatedCharacter? = nil
  @State private var subject: Subject? = nil

  func load() async {
    let fetcher = BackgroundFetcher(modelContext.container)
    do {
      character = try await fetcher.fetchOne(
        predicate: #Predicate<PersonRelatedCharacter> {
          $0.personId == personId && $0.characterId == characterId
        })
      subject = try await fetcher.fetchOne(
        predicate: #Predicate<Subject> {
          $0.subjectId == subjectId
        })
    } catch {
      notifier.alert(error: error)
    }
  }

  var body: some View {
    HStack(alignment: .bottom) {
      NavigationLink(value: NavDestination.character(characterId: characterId)) {
        ImageView(img: character?.images.medium, width: 60, height: 60, alignment: .top)
        VStack(alignment: .leading) {
          Text(character?.name ?? "")
            .foregroundStyle(Color("LinkTextColor"))
            .lineLimit(1)
            .padding(.bottom, 2)
          if let staff = character?.staff {
            Text(staff)
              .font(.footnote)
              .foregroundStyle(.secondary)
              .overlay {
                RoundedRectangle(cornerRadius: 4)
                  .stroke(Color.secondary, lineWidth: 1)
                  .padding(.horizontal, -2)
                  .padding(.vertical, -1)
              }
          }
        }
      }.buttonStyle(.plain)
      Spacer()
      NavigationLink(value: NavDestination.subject(subjectId: subjectId)) {
        HStack(alignment: .bottom) {
          VStack(alignment: .trailing) {
            Text(subject?.name ?? "")
              .foregroundStyle(Color("LinkTextColor"))
              .truncationMode(.middle)
              .lineLimit(1)
              .font(.footnote)
              .padding(.bottom, 2)
            HStack(alignment: .bottom) {
              Text(subject?.nameCn ?? "")
                .truncationMode(.middle)
                .foregroundStyle(.secondary)
                .lineLimit(1)
              if let icon = subject?.typeEnum.icon {
                Image(systemName: icon).foregroundStyle(.secondary)
              }
            }
            .font(.caption)
            .padding(.trailing, 2)
          }
          ImageView(img: subject?.images.small, width: 40, height: 40, type: .subject)
        }
      }.buttonStyle(.plain)
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
      PersonCharacterItemView(
        personId: person.personId, characterId: character.characterId, subjectId: subject.subjectId
      )
      .environmentObject(Notifier())
      .environment(ChiiClient(container: container, mock: .anime))
      .modelContainer(container)
    }.padding(.horizontal, 8)
  }
}
