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

  @Environment(Notifier.self) private var notifier
  @Environment(ChiiClient.self) private var chii
  @Environment(\.modelContext) var modelContext

  @State private var refreshed: Bool = false
  @State private var loaded: Bool = false

  @State private var characters: [SubjectRelatedCharacter] = []

  func load() async {
    let fetcher = BackgroundFetcher(modelContext.container)

    do {
      var mainDescriptor = FetchDescriptor<SubjectRelatedCharacter>(
        predicate: #Predicate<SubjectRelatedCharacter> {
          $0.subjectId == subjectId && $0.relation == "主角"
        },
        sortBy: [
          SortDescriptor<SubjectRelatedCharacter>(\.characterId)
        ])
      mainDescriptor.fetchLimit = 10
      let mains = try await fetcher.fetchData(mainDescriptor)
      characters = mains
      if mains.count < 10 {
        var sideDescriptor = FetchDescriptor<SubjectRelatedCharacter>(
          predicate: #Predicate<SubjectRelatedCharacter> {
            $0.subjectId == subjectId && $0.relation == "配角"
          },
          sortBy: [
            SortDescriptor<SubjectRelatedCharacter>(\.characterId)
          ])
        sideDescriptor.fetchLimit = 10 - mains.count
        let sides = try await fetcher.fetchData(sideDescriptor)
        characters.append(contentsOf: sides)
      }
    } catch {
      notifier.alert(error: error)
    }
    loaded = true
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
    await load()
  }

  var body: some View {
    if characters.count > 0 {
      Divider()
      HStack {
        Text("角色介绍").font(.title3)
        Spacer()
        NavigationLink(value: NavDestination.subjectCharacterList(subjectId: subjectId)) {
          Text("更多角色 »").font(.caption).foregroundStyle(Color("LinkTextColor"))
        }.buttonStyle(.plain)
      }
    } else if !loaded {
      ProgressView()
        .onAppear {
          Task {
            await load()
          }
        }
    } else if !refreshed {
      ProgressView()
        .onAppear {
          Task(priority: .background) {
            await refresh()
          }
        }
    }

    ScrollView(.horizontal, showsIndicators: false) {
      LazyHStack(alignment: .top) {
        ForEach(characters) { character in
          NavigationLink(value: NavDestination.character(characterId: character.characterId)) {
            VStack {
              Text(character.relation)
                .font(.caption)
                .foregroundStyle(.secondary)
                .overlay {
                  RoundedRectangle(cornerRadius: 5)
                    .stroke(Color.secondary, lineWidth: 1)
                    .padding(.horizontal, -4)
                    .padding(.vertical, -2)
                }.padding(.top, 4)
              ImageView(img: character.images.medium, width: 60, height: 80, alignment: .top)
              Text(character.name).font(.caption)
              if let person = character.actors.first {
                Text(person.name).foregroundStyle(.secondary).font(.caption2)
              }
              Spacer()
            }
            .lineLimit(1)
            .frame(width: 60, height: 160)
          }.buttonStyle(.plain)
        }
      }
    }.animation(.default, value: characters)
  }
}

#Preview {
  let container = mockContainer()

  let subject = Subject.previewAnime
  container.mainContext.insert(subject)

  return ScrollView {
    LazyVStack(alignment: .leading) {
      SubjectCharactersView(subjectId: subject.subjectId)
        .environment(Notifier())
        .environment(ChiiClient(container: container, mock: .anime))
        .modelContainer(container)
    }
  }.padding()
}
