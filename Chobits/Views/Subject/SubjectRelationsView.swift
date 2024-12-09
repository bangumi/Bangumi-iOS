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
  @State private var collections: [Int: CollectionType] = [:]

  @Query private var subjects: [Subject]
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

        var relationIDs: [Int] = []
        relationIDs.append(contentsOf: relations.map { $0.subject.id })
        relationIDs.append(contentsOf: offprints.map { $0.subject.id })
        let collectionDescriptor = FetchDescriptor<UserSubjectCollection>(
          predicate: #Predicate<UserSubjectCollection> {
            relationIDs.contains($0.subjectId)
          })
        let collects = try modelContext.fetch(collectionDescriptor)
        for collection in collects {
          self.collections[collection.subjectId] = collection.typeEnum
        }
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
                if let ctype = collections[offprint.subject.id] {
                  ImageView(
                    img: offprint.subject.images?.common,
                    width: 60, height: 80, type: .subject, overlay: .caption
                  ) {
                    HStack {
                      Image(systemName: ctype.icon)
                      Spacer()
                      Text(ctype.description(type: offprint.subject.type))
                    }.padding(.horizontal, 4)
                  }
                } else {
                  ImageView(
                    img: offprint.subject.images?.common,
                    width: 60, height: 80, type: .subject)
                }
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
              Section {
                if relation.relation.cn.isEmpty {
                  Text(relation.subject.type.description)
                } else {
                  Text(relation.relation.cn)
                }
              }
              .lineLimit(1)
              .font(.caption)

              if let ctype = collections[relation.subject.id] {
                ImageView(
                  img: relation.subject.images?.common,
                  width: 90, height: 120,
                  type: .subject, overlay: .caption
                ) {
                  HStack {
                    Image(systemName: ctype.icon)
                    Spacer()
                    Text(ctype.description(type: relation.subject.type))
                  }.padding(.horizontal, 4)
                }
              } else {
                ImageView(
                  img: relation.subject.images?.common,
                  width: 90, height: 120, type: .subject
                )
              }
              Text(relation.subject.name)
                .font(.caption)
                .multilineTextAlignment(.leading)
                .truncationMode(.middle)
                .lineLimit(2)
              Spacer()
            }.frame(width: 90, height: 185)
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
