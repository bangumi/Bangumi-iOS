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

  @EnvironmentObject var notifier: Notifier
  @EnvironmentObject var chii: ChiiClient

  @State private var refreshed: Bool = false

  @Query
  private var relations: [SubjectRelation]

  init(subjectId: UInt) {
    self.subjectId = subjectId
    _relations = Query(
      filter: #Predicate<SubjectRelation> {
        $0.subjectId == subjectId
      }, sort: \SubjectRelation.sort)
  }

  func refresh() async {
    if refreshed { return }
    refreshed = true

    do {
      try await chii.loadSubjectRelations(subjectId)
      try await chii.db.save()
    } catch {
      notifier.alert(error: error)
    }
  }

  var body: some View {
    VStack {
      HStack{
        Text("关联条目").font(.title3)
        Spacer()
        Text("更多条目 »").font(.caption)
      }
    }.onAppear {
      Task(priority: .background) {
        await refresh()
      }
    }
    ScrollView(.horizontal) {
      LazyHStack {
        ForEach(relations) { relation in
          VStack {
            Text(relation.relation).foregroundStyle(.secondary)
            ImageView(img: relation.images.grid, width: 60, height: 60)
            Text(relation.name)
              .multilineTextAlignment(.leading)
              .lineLimit(3)
            Spacer()
          }
          .font(.caption2)
          .frame(width: 60, height: 132)
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
      SubjectRelationsView(subjectId: subject.id)
        .environmentObject(Notifier())
        .environment(ChiiClient(container: container, mock: .anime))
        .modelContainer(container)
    }
  }.padding()
}
