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
  @Environment(\.modelContext) var modelContext

  @State private var loaded: Bool = false
  @State private var refreshing: Bool = false
  @State private var relations: [SubjectRelation] = []

  func load() async {
    do {
      var descriptor = FetchDescriptor<SubjectRelation>(
        predicate: #Predicate<SubjectRelation> {
          $0.subjectId == subjectId
        }, sortBy: [SortDescriptor<SubjectRelation>(\.relationId)])
      descriptor.fetchLimit = 10
      relations = try modelContext.fetch(descriptor)
    } catch {
      notifier.alert(error: error)
    }
  }

  func refresh() {
    if loaded {
      return
    }
    refreshing = true
    Task {
      await load()
      do {
        try await Chii.shared.loadSubjectRelations(subjectId)
      } catch {
        notifier.alert(error: error)
      }
      await load()
      refreshing = false
      loaded = true
    }
  }

  var body: some View {
    Divider()
    HStack {
      Text("关联条目")
        .foregroundStyle(relations.count > 0 ? .primary : .secondary)
        .font(.title3)
        .onAppear(perform: refresh)
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
