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
  @State private var singles: [SubjectRelation] = []
  @State private var relations: [SubjectRelation] = []

  @Query
  private var subjects: [Subject]
  private var subject: Subject? { subjects.first }

  init(subjectId: UInt) {
    self.subjectId = subjectId
    _subjects = Query(
      filter: #Predicate<Subject> {
        $0.subjectId == subjectId
      })
  }

  func load() async {
    let singleRelation = "单行本"
    do {
      var descriptor = FetchDescriptor<SubjectRelation>(
        predicate: #Predicate<SubjectRelation> {
          $0.subjectId == subjectId && $0.relation != singleRelation
        }, sortBy: [SortDescriptor<SubjectRelation>(\.relationId)])
      descriptor.fetchLimit = 10
      relations = try modelContext.fetch(descriptor)

      let singleDescriptor = FetchDescriptor<SubjectRelation>(
        predicate: #Predicate<SubjectRelation> {
          $0.subjectId == subjectId && $0.relation == singleRelation
        }, sortBy: [SortDescriptor<SubjectRelation>(\.relationId)])
      singles = try modelContext.fetch(singleDescriptor)
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
    if subject?.series ?? false {
      Divider()
      HStack {
        Text("单行本")
          .foregroundStyle(singles.count > 0 ? .primary : .secondary)
          .font(.title3)
        Spacer()
      }
      ScrollView(.horizontal, showsIndicators: false) {
        LazyHStack {
          ForEach(singles) { relation in
            NavigationLink(value: NavDestination.subject(subjectId: relation.relationId)) {
              VStack {
                ImageView(img: relation.images.common, width: 60, height: 90, type: .subject)
                Spacer()
              }.font(.caption2).frame(width: 60, height: 90)
            }.buttonStyle(.plain)
          }
        }
      }.animation(.default, value: singles)
    }

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
              ImageView(img: relation.images.common, width: 90, height: 120, type: .subject)
              Text(relation.name)
                .multilineTextAlignment(.leading)
                .truncationMode(.middle)
                .lineLimit(2)
              Spacer()
            }.font(.caption2).frame(width: 90, height: 180)
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
