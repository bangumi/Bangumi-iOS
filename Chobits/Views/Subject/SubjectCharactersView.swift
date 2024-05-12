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

  @EnvironmentObject var notifier: Notifier
  @EnvironmentObject var chii: ChiiClient

  @State private var refreshed: Bool = false
  @State private var counts: Int = 0

  @Query
  private var characters: [SubjectRelatedCharacter]

  init(subjectId: UInt) {
    self.subjectId = subjectId
    var descriptor = FetchDescriptor<SubjectRelatedCharacter>(
      predicate: #Predicate<SubjectRelatedCharacter> {
        $0.subjectId == subjectId
      }, sortBy: [
        SortDescriptor<SubjectRelatedCharacter>(\.relation),
        SortDescriptor<SubjectRelatedCharacter>(\.characterId)
      ])
    descriptor.fetchLimit = 10
    _characters = Query(descriptor)
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
  }

  var body: some View {
    if characters.count > 0 {
      HStack {
        Text("角色介绍").font(.title3)
        Spacer()
        NavigationLink(value: NavDestination.subjectCharacterList(subjectId: subjectId)) {
          Text("更多角色 »").font(.caption).foregroundStyle(Color("LinkTextColor"))
        }.buttonStyle(.plain)
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
              if let actor = character.actors.first {
                Text("CV: \(actor.name)").foregroundStyle(.secondary).font(.caption2)
              }
              Spacer()
            }
            .lineLimit(1)
            .frame(width: 80, height: 160)
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
      SubjectCharactersView(subjectId: subject.id)
        .environmentObject(Notifier())
        .environment(ChiiClient(container: container, mock: .anime))
        .modelContainer(container)
    }
  }.padding()
}
