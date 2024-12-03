//
//  PersonWorkListView.swift
//  Chobits
//
//  Created by Chuan Chuan on 2024/5/12.
//

import Flow
import SwiftData
import SwiftUI

struct PersonWorkListView: View {
  let personId: Int

  @State private var subjectType: SubjectType = .none
  @State private var reloader = false

  func load(limit: Int, offset: Int) async -> PagedDTO<PersonWorkDTO>? {
    do {
      let resp = try await Chii.shared.getPersonWorks(
        personId, subjectType: subjectType, limit: limit, offset: offset)
      return resp
    } catch {
      Notifier.shared.alert(error: error)
    }
    return nil
  }

  var body: some View {
    Picker("Subject Type", selection: $subjectType) {
      ForEach(SubjectType.allCases) { type in
        Text(type.description).tag(type)
      }
    }
    .padding(.horizontal, 8)
    .pickerStyle(.segmented)
    .onChange(of: subjectType) { _, _ in
      reloader.toggle()
    }
    ScrollView {
      PageView<PersonWorkDTO, _>(limit: 10, reloader: reloader, nextPageFunc: load) { item in
        CardView {
          NavigationLink(value: NavDestination.subject(subjectId: item.subject.id)) {
            HStack {
              ImageView(img: item.subject.images?.medium, width: 64, height: 64, type: .subject)
              VStack(alignment: .leading) {
                Text(item.subject.name)
                  .font(.callout)
                  .foregroundStyle(.linkText)
                  .lineLimit(1)
                Text(item.subject.nameCN)
                  .font(.footnote)
                  .foregroundStyle(.secondary)
                  .lineLimit(1)
                HStack {
                  Image(systemName: item.subject.type.icon)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                  BorderView {
                    Text(item.position.cn)
                      .font(.caption)
                      .foregroundStyle(.secondary)
                  }
                }
              }.padding(.leading, 4)
              Spacer()
            }
          }
        }
      }
      .padding(8)
    }
    .buttonStyle(.plain)
    .navigationTitle("参与作品")
    .navigationBarTitleDisplayMode(.inline)
    .toolbar {
      ToolbarItem(placement: .automatic) {
        Image(systemName: "list.bullet.circle").foregroundStyle(.secondary)
      }
    }
  }
}

#Preview {
  let person = Person.preview
  return PersonWorkListView(personId: person.personId)
}
