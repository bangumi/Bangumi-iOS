//
//  SubjectCharactersView.swift
//  Chobits
//
//  Created by Chuan Chuan on 2024/5/9.
//

import SwiftData
import SwiftUI

struct SubjectCharactersView: View {
  let subjectId: Int

  @Environment(\.modelContext) var modelContext

  @State private var loaded: Bool = false
  @State private var loading: Bool = false
  @State private var relations: [SubjectCharacterDTO] = []

  func load() async {
    if loading || loaded {
      return
    }
    loading = true
    do {
      let resp = try await Chii.shared.getSubjectCharacters(subjectId, limit: 10)
      relations.append(contentsOf: resp.data)
    } catch {
      Notifier.shared.alert(error: error)
    }
    loading = false
    loaded = true
  }

  var body: some View {
    Divider()
    HStack {
      Text("角色介绍")
        .foregroundStyle(relations.count > 0 ? .primary : .secondary)
        .font(.title3)
        .task(load)
      if loading {
        ProgressView()
      }
      Spacer()
      if relations.count > 0 {
        NavigationLink(value: NavDestination.subjectCharacterList(subjectId: subjectId)) {
          Text("更多角色 »").font(.caption).foregroundStyle(.linkText)
        }.buttonStyle(.plain)
      }
    }
    ScrollView(.horizontal, showsIndicators: false) {
      LazyHStack(alignment: .top) {
        ForEach(relations, id: \.character.id) { item in
          NavigationLink(value: NavDestination.character(characterId: item.character.id)) {
            VStack {
              ImageView(
                img: item.character.images?.medium, width: 60, height: 80, alignment: .top,
                overlay: .caption
              ) {
                Text(item.type.description)
              }
              Text(item.character.name).font(.caption)
              if let person = item.actors.first {
                Text(person.name).foregroundStyle(.secondary).font(.caption2)
              }
              Spacer()
            }
            .lineLimit(1)
            .frame(width: 60, height: 120)
          }.buttonStyle(.plain)
        }
      }
    }.animation(.default, value: relations)
  }
}

#Preview {
  let container = mockContainer()

  let subject = Subject.previewAnime
  container.mainContext.insert(subject)

  return NavigationStack {
    ScrollView {
      LazyVStack(alignment: .leading) {
        SubjectCharactersView(subjectId: subject.subjectId)
          .modelContainer(container)
      }
    }.padding()
  }
}
