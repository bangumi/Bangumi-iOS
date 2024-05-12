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

  @EnvironmentObject var notifier: Notifier
  @EnvironmentObject var chii: ChiiClient

  @Query
  private var relations: [SubjectRelation]

  init(subjectId: UInt) {
    self.subjectId = subjectId
    let descriptor = FetchDescriptor<SubjectRelation>(
      predicate: #Predicate<SubjectRelation> {
        $0.subjectId == subjectId
      }, sortBy: [SortDescriptor<SubjectRelation>(\.sort)])
    _relations = Query(descriptor)
  }

  var body: some View {
    ScrollView {
      LazyVStack(alignment: .leading) {
        ForEach(relations) { subject in
          Text(subject.name)
        }
      }
    }
    .padding(.horizontal, 8)
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

  return SubjectRelationListView(subjectId: subject.id)
    .environmentObject(Notifier())
    .environment(ChiiClient(container: container, mock: .anime))
    .modelContainer(container)
}
