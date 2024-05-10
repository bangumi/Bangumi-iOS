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
  @State private var counts: Int = 0

  @Query
  private var relations: [SubjectRelation]

  init(subjectId: UInt) {
    self.subjectId = subjectId
    var descriptor = FetchDescriptor<SubjectRelation>(
      predicate: #Predicate<SubjectRelation> {
        $0.subjectId == subjectId
      }, sortBy: [SortDescriptor<SubjectRelation>(\.sort)])
    descriptor.fetchLimit = 10
    _relations = Query(descriptor)
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
    await loadCounts()
  }

  func loadCounts() async {
    do {
      let counts = try await chii.db.fetchCount(
        predicate: #Predicate<SubjectRelation> {
          $0.subjectId == subjectId
        })
      self.counts = counts
    } catch {
      notifier.alert(error: error)
    }
  }

  var body: some View {
    VStack {
      HStack {
        Text("关联条目").font(.title3)
        Spacer()
        if counts > 10 {
          Text("更多条目 »").font(.caption)
        }
      }
    }.onAppear {
      Task(priority: .background) {
        await loadCounts()
        await refresh()
      }
    }
    ScrollView(.horizontal) {
      LazyHStack {
        ForEach(relations) { relation in
          NavigationLink(value: NavDestination.subject(subjectId: relation.relationId)) {
            VStack {
              Text(relation.relation).foregroundStyle(.secondary)
              ImageView(img: relation.images.grid, width: 60, height: 60)
              Text(relation.name)
                .multilineTextAlignment(.leading)
                .truncationMode(.middle)
                .lineLimit(3)
              Spacer()
            }.font(.caption2).frame(width: 60, height: 150)
          }.buttonStyle(.plain)
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
