//
//  SubjectRelationListView.swift
//  Chobits
//
//  Created by Chuan Chuan on 2024/5/12.
//

import SwiftData
import SwiftUI

struct SubjectRelationListView: View {
  let subjectId: UInt

  @Environment(Notifier.self) private var notifier
  @Environment(\.modelContext) var modelContext

  @State private var subjectType: SubjectType = .unknown
  @State private var relations: [SubjectRelation] = []

  func load() async {
    let stype = subjectType.rawValue
    let zero: UInt8 = 0
    let descriptor = FetchDescriptor<SubjectRelation>(
      predicate: #Predicate<SubjectRelation> {
        if stype == zero {
          return $0.subjectId == subjectId
        } else {
          return $0.subjectId == subjectId && $0.type == stype
        }
      }, sortBy: [SortDescriptor<SubjectRelation>(\.relationId)])
    do {
      relations = try modelContext.fetch(descriptor)
    } catch {
      notifier.alert(error: error)
    }
  }

  var body: some View {
    Picker("Subject Type", selection: $subjectType) {
      ForEach(SubjectType.allCases) { type in
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
    .onChange(of: subjectType) { _, _ in
      Task {
        await load()
      }
    }
    ScrollView {
      LazyVStack(alignment: .leading) {
        ForEach(relations) { subject in
          NavigationLink(value: NavDestination.subject(subjectId: subject.relationId)) {
            HStack {
              ImageView(img: subject.images.common, width: 60, height: 60, type: .subject)
              VStack(alignment: .leading) {
                Text(subject.name)
                  .foregroundStyle(.linkText)
                  .lineLimit(1)
                Text(subject.nameCn)
                  .font(.footnote)
                  .foregroundStyle(.secondary)
                  .lineLimit(1)
                Label(subject.relation, systemImage: subject.typeEnum.icon)
                  .font(.footnote)
                  .foregroundStyle(.secondary)
              }
            }
          }.buttonStyle(.plain)
        }
      }.padding(.horizontal, 8)
    }
    .buttonStyle(.plain)
    .animation(.default, value: relations)
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
  let subjectRelations = SubjectRelation.preview
  container.mainContext.insert(subject)
  for item in subjectRelations {
    container.mainContext.insert(item)
  }

  return SubjectRelationListView(subjectId: subject.subjectId)
    .environment(Notifier())
    .modelContainer(container)
}
