//
//  SubjectRelationListView.swift
//  Chobits
//
//  Created by Chuan Chuan on 2024/5/12.
//

import SwiftData
import SwiftUI

struct SubjectRelationListView: View {
  let subjectId: Int

  @State private var subjectType: SubjectType = .none
  @State private var reloader = false

  func load(limit: Int, offset: Int) async -> PagedData<SubjectRelationDTO>? {
    do {
      let resp = try await Chii.shared.getSubjectRelations(
        subjectId, type: subjectType, limit: limit, offset: offset)
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
      PageView<SubjectRelationDTO, _>(reloader: reloader, nextPageFunc: load) { item in
        Section {
          HStack {
            NavigationLink(value: NavDestination.subject(subjectId: item.subject.id)) {
              ImageView(
                img: item.subject.images?.medium,
                width: 60, height: 60, type: .subject
              )
            }
            .buttonStyle(.plain)
            VStack(alignment: .leading) {
              NavigationLink(value: NavDestination.subject(subjectId: item.subject.id)) {
                HStack {
                  VStack(alignment: .leading) {
                    Text(item.subject.name)
                      .foregroundStyle(.linkText)
                      .lineLimit(1)
                    Text(item.subject.nameCN)
                      .font(.footnote)
                      .foregroundStyle(.secondary)
                      .lineLimit(1)
                    Label(item.relation.cn, systemImage: item.subject.type.icon)
                      .font(.footnote)
                      .foregroundStyle(.secondary)
                  }
                  Spacer()
                }
              }.buttonStyle(.plain)
            }.padding(.leading, 4)
          }.padding(4)
        }
        .background(Color("CardBackgroundColor"))
        .cornerRadius(8)
        .shadow(color: Color.black.opacity(0.2), radius: 4)
      }
      .padding(8)
    }
    .buttonStyle(.plain)
    .navigationTitle("关联条目")
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
  container.mainContext.insert(subject)

  return SubjectRelationListView(subjectId: subject.subjectId)
    .modelContainer(container)
}
