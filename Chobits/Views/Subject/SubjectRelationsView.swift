//
//  SubjectRelationsView.swift
//  Chobits
//
//  Created by Chuan Chuan on 2024/5/8.
//

import Foundation
import SwiftData
import SwiftUI

struct SubjectRelationsView: View {
  let subjectId: Int
  let series: Bool

  @Environment(\.modelContext) var modelContext

  @State private var loaded: Bool = false
  @State private var loading: Bool = false
  @State private var relations: [SubjectRelationDTO] = []
  @State private var offprints: [SubjectRelationDTO] = []

  @Query
  private var subjects: [Subject]
  var subject: Subject? { subjects.first }

  func load() {
    if loading || loaded {
      return
    }
    loading = true
    Task {
      do {
        let offprintResp = try await Chii.shared.getSubjectRelations(
          subjectId, offprint: true, limit: 100)
        offprints.append(contentsOf: offprintResp.data)
        let relationResp = try await Chii.shared.getSubjectRelations(subjectId, limit: 10)
        relations.append(contentsOf: relationResp.data)
      } catch {
        Notifier.shared.alert(error: error)
      }
      loading = false
      loaded = true
    }
  }

  var body: some View {
    if series {
      Divider()
      HStack {
        Text("单行本")
          .foregroundStyle(offprints.count > 0 ? .primary : .secondary)
          .font(.title3)
        Spacer()
      }
      ScrollView(.horizontal, showsIndicators: false) {
        LazyHStack {
          ForEach(offprints) { offprint in
            NavigationLink(value: NavDestination.subject(subjectId: offprint.subject.id)) {
              VStack {
                ImageView(
                  img: offprint.subject.images?.common,
                  width: 60, height: 80, type: .subject)
                Spacer()
              }
              .font(.caption)
              .frame(width: 60, height: 90)
            }.buttonStyle(.plain)
          }
        }
      }.animation(.default, value: offprints)
    }

    Divider()
    HStack {
      Text("关联条目")
        .foregroundStyle(relations.count > 0 ? .primary : .secondary)
        .font(.title3)
        .onAppear(perform: load)
      if loading {
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
          NavigationLink(value: NavDestination.subject(subjectId: relation.subject.id)) {
            VStack {
              ImageView(
                img: relation.subject.images?.common,
                width: 90, height: 120,
                type: .subject, overlay: .caption
              ) {
                VStack {
                  if relation.relation.cn.isEmpty {
                    Text(relation.subject.type.description)
                  } else {
                    Text(relation.relation.cn)
                  }
                }
                .lineLimit(1)
                .font(.caption)
                .foregroundStyle(.white)
              }
              Text(relation.subject.name)
                .font(.caption)
                .multilineTextAlignment(.leading)
                .truncationMode(.middle)
                .lineLimit(2)
              Spacer()
            }.frame(width: 90, height: 165)
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
      SubjectRelationsView(subjectId: subject.subjectId, series: subject.series)
        .modelContainer(container)
    }
  }.padding()
}
