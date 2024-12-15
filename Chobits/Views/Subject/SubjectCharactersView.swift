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
  let characters: [SubjectCharacterDTO]

  var body: some View {
    VStack(spacing: 2) {
      HStack(alignment: .bottom) {
        Text("角色介绍")
          .foregroundStyle(characters.count > 0 ? .primary : .secondary)
          .font(.title3)
        Spacer()
        if characters.count > 0 {
          NavigationLink(value: NavDestination.subjectCharacterList(subjectId)) {
            Text("更多角色 »").font(.caption)
          }.buttonStyle(.navLink)
        }
      }
      Divider()
    }.padding(.top, 5)
    if characters.count == 0 {
      HStack {
        Spacer()
        Text("暂无角色")
          .font(.caption)
          .foregroundStyle(.secondary)
        Spacer()
      }.padding(.bottom, 5)
    }
    ScrollView(.horizontal, showsIndicators: false) {
      LazyHStack(alignment: .top) {
        ForEach(characters, id: \.character.id) { item in
          VStack {
            NavigationLink(value: NavDestination.character(item.character.id)) {
              ImageView(
                img: item.character.images?.medium, width: 60, height: 80, alignment: .top
              ) {
              } caption: {
                Text(item.type.description)
                  .foregroundStyle(.white)
                  .lineLimit(1)
              }
            }.buttonStyle(.plain)
            Text(item.character.name).font(.caption)
            if let person = item.actors.first {
              Text(person.name).foregroundStyle(.secondary).font(.caption)
            }
            Spacer()
          }
          .lineLimit(1)
          .frame(width: 60, height: 120)
        }
      }
    }.animation(.default, value: characters)
  }
}

#Preview {
  NavigationStack {
    ScrollView {
      LazyVStack(alignment: .leading) {
        SubjectCharactersView(
          subjectId: Subject.previewAnime.subjectId, characters: Subject.previewCharacters)
      }.padding()
    }
  }
}
