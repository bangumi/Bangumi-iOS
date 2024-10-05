//
//  SubjectRelationsView.swift
//  Chobits
//
//  Created by Chuan Chuan on 2024/5/8.
//

import SwiftData
import SwiftUI

struct SubjectRelationsView: View {
  let subjectId: UInt

  @Environment(Notifier.self) private var notifier

  @State private var refreshing: Bool = false
  @State private var counts: Int = 0

  @Query
  private var relations: [SubjectRelation]

  init(subjectId: UInt) {
    self.subjectId = subjectId
    var descriptor = FetchDescriptor<SubjectRelation>(
      predicate: #Predicate<SubjectRelation> {
        $0.subjectId == subjectId
      }, sortBy: [SortDescriptor<SubjectRelation>(\.relationId)])
    descriptor.fetchLimit = 10
    _relations = Query(descriptor)
  }

  func refresh() async {
    if relations.count > 0 {
      return
    }
    refreshing = true
    do {
      try await Chii.shared.loadSubjectRelations(subjectId)
    } catch {
      notifier.alert(error: error)
    }
    refreshing = false
  }

  var body: some View {
    Divider()
    HStack {
      Text("关联条目")
        .foregroundStyle(relations.count > 0 ? .primary : .secondary)
        .font(.title3)
        .task {
          await refresh()
        }
      if refreshing {
        ProgressView()
      }
      Spacer()
      if relations.count > 0 {
        NavigationLink(value: NavDestination.subjectRelationList(subjectId: subjectId)) {
          Text("更多条目 »").font(.caption).foregroundStyle(.linkText)
        }.buttonStyle(.plain)
      }
    }
    ScrollView(.horizontal, showsIndicators: false) {
      LazyHStack {
        ForEach(relations) { relation in
          NavigationLink(value: NavDestination.subject(subjectId: relation.relationId)) {
            VStack {
              Text(relation.relation).foregroundStyle(.secondary)
              ImageView(img: relation.images.grid, width: 60, height: 60, type: .subject)
              Text(relation.name)
                .multilineTextAlignment(.leading)
                .truncationMode(.middle)
                .lineLimit(2)
              Spacer()
            }.font(.caption2).frame(width: 60, height: 120)
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

  return ScrollView {
    LazyVStack(alignment: .leading) {
      SubjectRelationsView(subjectId: subject.subjectId)
        .environment(Notifier())
        .modelContainer(container)
    }
  }.padding()
}
