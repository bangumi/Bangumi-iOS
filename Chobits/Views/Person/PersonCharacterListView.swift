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

  @EnvironmentObject var notifier: Notifier
  @EnvironmentObject var chii: ChiiClient
  @Environment(\.modelContext) var modelContext

  @State private var relationType: SubjectCharacterRelationType = .unknown
  @State private var characters: [PersonRelatedCharacter] = []

  func load() async {
    let rtype = relationType.description
    let allType = SubjectCharacterRelationType.unknown.description
    let fetcher = BackgroundFetcher(modelContext.container)
    let descriptor = FetchDescriptor<PersonRelatedCharacter>(
      predicate: #Predicate<PersonRelatedCharacter> {
        if rtype == allType {
          return $0.personId == personId
        } else {
          return $0.personId == personId && $0.staff == rtype
        }
      },
      sortBy: [
        SortDescriptor<PersonRelatedCharacter>(\.staff),
        SortDescriptor<PersonRelatedCharacter>(\.characterId, order: .reverse),
      ])
    do {
      characters = try await fetcher.fetchData(descriptor)
    } catch {
      notifier.alert(error: error)
    }
  }

  var characterList: [(PersonRelatedCharacter, [PersonRelatedCharacter])] {
    let chars = Dictionary(grouping: characters, by: { $0.characterId })
    var groupedResults: [(PersonRelatedCharacter, [PersonRelatedCharacter])] = []
    for (_, sublist) in chars {
      if let firstCharacter = sublist.first {
        groupedResults.append((firstCharacter, sublist))
      }
    }
    return groupedResults
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
        ForEach(characterList, id: \.0.self) { character, subjects in
          Divider()
          HStack(alignment: .top) {
            NavigationLink(value: NavDestination.character(characterId: character.characterId)) {
              ImageView(img: character.images.medium, width: 60, height: 60, alignment: .top)
              VStack(alignment: .leading) {
                HStack {
                  Text(character.name)
                    .foregroundStyle(Color("LinkTextColor"))
                    .lineLimit(1)
                }
              }
            }.buttonStyle(.plain)
            Spacer()
            VStack(alignment: .trailing) {
              ForEach(subjects) { subject in
                NavigationLink(value: NavDestination.subject(subjectId: character.subjectId)) {
                  HStack(alignment: .bottom) {
                    VStack(alignment: .trailing) {
                      HStack(alignment: .bottom) {
                        Text(subject.subjectNameCn)
                          .font(.caption)
                          .foregroundStyle(.secondary)
                          .lineLimit(1)
                        Text(subject.staff)
                          .font(.footnote)
                          .foregroundStyle(.secondary)
                          .overlay {
                            RoundedRectangle(cornerRadius: 4)
                              .stroke(Color.secondary, lineWidth: 1)
                              .padding(.horizontal, -2)
                              .padding(.vertical, -1)
                          }
                      }.padding(.trailing, 2)
                      Text(subject.subjectName)
                        .font(.footnote)
                        .foregroundStyle(Color("LinkTextColor"))
                        .lineLimit(1)
                    }
                  }
                }
                .padding(.vertical, 2)
                .buttonStyle(.plain)
              }
            }
          }
        }
      }
    }
    .padding(.horizontal, 8)
    .buttonStyle(.plain)
    .animation(.default, value: characters)
    .navigationTitle("出演角色")
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

  let person = Person.preview
  let personCharacters = PersonRelatedCharacter.preview
  container.mainContext.insert(person)
  for item in personCharacters {
    container.mainContext.insert(item)
  }

  return PersonCharacterListView(personId: person.personId)
    .environmentObject(Notifier())
    .environment(ChiiClient(container: container, mock: .anime))
    .modelContainer(container)
}
