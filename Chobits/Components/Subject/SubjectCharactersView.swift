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

  @Query
  private var characters: [SubjectRelatedCharacter]

  init(subjectId: UInt) {
    self.subjectId = subjectId
    var descriptor = FetchDescriptor<SubjectRelatedCharacter>(
      predicate: #Predicate<SubjectRelatedCharacter> {
        $0.subjectId == subjectId
      }, sortBy: [SortDescriptor<SubjectRelatedCharacter>(\.sort)])
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
    VStack {
      HStack {
        Text("角色介绍").font(.title3)
        Spacer()
        if characters.count > 10 {
          Text("更多角色 »").font(.caption)
        }
      }
    }.onAppear {
      Task(priority: .background) {
        await refresh()
      }
    }
    ScrollView(.horizontal) {
      LazyHStack(alignment: .top) {
        ForEach(characters) { character in
          VStack {
            Text(character.relation)
              .foregroundStyle(.secondary)
              .overlay {
                RoundedRectangle(cornerRadius: 5)
                  .stroke(Color.secondary, lineWidth: 1)
                  .padding(.horizontal, -4)
                  .padding(.vertical, -2)
              }.padding(.top, 4)
            ImageView(img: character.images.grid, width: 80, height: 80)
            Text(character.name)
            if let actor = character.actors.first {
              Text("CV:\(actor.name)").foregroundStyle(.secondary)
            }
            Spacer()
          }
          .lineLimit(1)
          .font(.caption2)
          .frame(width: 80, height: 150)
        }
      }
    }
  }
}

#Preview {
  let container = mockContainer()

  let subject = Subject.previewAnime

  return ScrollView {
    LazyVStack(alignment: .leading) {
      SubjectCharactersView(subjectId: subject.id)
        .environmentObject(Notifier())
        .environment(ChiiClient(container: container, mock: .anime))
        .modelContainer(container)
    }
  }.padding()
}
