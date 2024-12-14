//
//  SubjectCharacterListView.swift
//  Chobits
//
//  Created by Chuan Chuan on 2024/5/12.
//

import Flow
import SwiftData
import SwiftUI

struct SubjectCharacterListView: View {
  let subjectId: Int

  @State private var castType: CastType = .none
  @State private var reloader = false

  func load(limit: Int, offset: Int) async -> PagedDTO<SubjectCharacterDTO>? {
    do {
      let resp = try await Chii.shared.getSubjectCharacters(
        subjectId, type: castType, limit: limit, offset: offset)
      return resp
    } catch {
      Notifier.shared.alert(error: error)
    }
    return nil
  }

  var body: some View {
    Picker("Cast Type", selection: $castType) {
      ForEach(CastType.allCases) { type in
        Text(type.description).tag(type)
      }
    }
    .padding(.horizontal, 8)
    .pickerStyle(.segmented)
    .onChange(of: castType) { _, _ in
      reloader.toggle()
    }
    ScrollView {
      PageView<SubjectCharacterDTO, _>(limit: 10, reloader: reloader, nextPageFunc: load) { item in
        CardView {
          HStack {
            NavigationLink(value: NavDestination.character(item.character.id)) {
              ImageView(
                img: item.character.images?.medium,
                width: 60, height: 90, alignment: .top
              ) {
              } caption: {
                Text(item.type.description)
                  .font(.caption)
                  .foregroundStyle(.white)
              }
            }
            VStack(alignment: .leading) {
              NavigationLink(value: NavDestination.character(item.character.id)) {
                HStack {
                  VStack(alignment: .leading) {
                    Text(item.character.name)
                      .lineLimit(1)
                    Text(item.character.nameCN)
                      .font(.footnote)
                      .foregroundStyle(.secondary)
                      .lineLimit(1)
                  }
                  Spacer()
                }
              }
              HFlow {
                ForEach(item.actors) { person in
                  NavigationLink(value: NavDestination.person(person.id)) {
                    HStack {
                      ImageView(
                        img: person.images?.grid,
                        width: 40, height: 40, alignment: .top, type: .subject
                      )
                      VStack(alignment: .leading) {
                        Text(person.name)
                          .font(.footnote)
                          .lineLimit(1)
                        Text(person.nameCN)
                          .font(.footnote)
                          .foregroundStyle(.secondary)
                          .lineLimit(1)
                      }
                    }
                  }
                }
              }
            }.padding(.leading, 4)
          }
        }
      }
      .padding(8)
    }
    .buttonStyle(.plain)
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
  let subject = Subject.previewAnime
  return SubjectCharacterListView(subjectId: subject.subjectId)
}
