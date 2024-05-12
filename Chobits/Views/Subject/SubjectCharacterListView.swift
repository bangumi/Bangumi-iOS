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
      }, sortBy: [SortDescriptor<SubjectRelatedCharacter>(\.characterId)])
    _characters = Query(descriptor)
  }

  var body: some View {
    ScrollView {
      LazyVStack(alignment: .leading) {
        ForEach(characters) { character in
          HStack(alignment: .bottom) {
            NavigationLink(value: NavDestination.character(characterId: character.characterId)) {
              ImageView(img: character.images.medium, width: 60, height: 60, alignment: .top)
              VStack(alignment: .leading) {
                HStack {
                  Text(character.name)
                    .foregroundStyle(Color("LinkTextColor"))
                    .lineLimit(1)
                }
                HStack(alignment: .bottom) {
                  Text(character.relation)
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
            if let person = character.actors.first {
              NavigationLink(value: NavDestination.person(personId: person.id)) {
                HStack(alignment: .bottom) {
                  VStack(alignment: .trailing) {
                    Text("CV")
                      .font(.caption)
                      .foregroundStyle(.secondary)
                    Text(person.name)
                      .font(.footnote)
                      .foregroundStyle(Color("LinkTextColor"))
                  }
                  if let img = person.images?.grid {
                    ImageView(img: img, width: 40, height: 40, alignment: .top)
                  }
                }
              }.buttonStyle(.plain)
            }
          }
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
