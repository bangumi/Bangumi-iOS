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
  @Environment(\.modelContext) var modelContext

  @State private var relationType: SubjectCharacterRelationType = .unknown
  @State private var characters: [SubjectRelatedCharacter] = []

  func load() async {
    let rtype = relationType.description
    let fetcher = BackgroundFetcher(modelContext.container)
    let descriptor = FetchDescriptor<SubjectRelatedCharacter>(
      predicate: #Predicate<SubjectRelatedCharacter> {
        if rtype == "全部" {
          return $0.subjectId == subjectId
        } else {
          return $0.subjectId == subjectId && $0.relation == rtype
        }
      },
      sortBy: [
        SortDescriptor<SubjectRelatedCharacter>(\.relation),
        SortDescriptor<SubjectRelatedCharacter>(\.characterId),
      ])
    do {
      characters = try await fetcher.fetchData(descriptor)
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
            if let actor = character.actors.first {
              NavigationLink(value: NavDestination.person(personId: actor.id)) {
                HStack(alignment: .bottom) {
                  VStack(alignment: .trailing) {
                    Text("CV")
                      .font(.caption)
                      .foregroundStyle(.secondary)
                    Text(actor.name)
                      .font(.footnote)
                      .foregroundStyle(Color("LinkTextColor"))
                  }
                  if let img = actor.images?.grid {
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

  return SubjectCharacterListView(subjectId: subject.subjectId)
    .environmentObject(Notifier())
    .environment(ChiiClient(container: container, mock: .anime))
    .modelContainer(container)

}
