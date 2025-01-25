import Foundation
import SwiftData
import SwiftUI

struct SubjectRelationsView: View {
  let subjectId: Int
  let relations: [SubjectRelationDTO]

  @Environment(\.modelContext) var modelContext

  @Query private var collects: [UserSubjectCollection]

  init(subjectId: Int, relations: [SubjectRelationDTO]) {
    self.subjectId = subjectId
    self.relations = relations
    let relationIDs = relations.map { $0.subject.id }
    let descriptor = FetchDescriptor<UserSubjectCollection>(
      predicate: #Predicate<UserSubjectCollection> {
        relationIDs.contains($0.subjectId)
      })
    _collects = Query(descriptor)
  }

  var collections: [Int: CollectionType] {
    collects.reduce(into: [:]) { $0[$1.subjectId] = $1.typeEnum }
  }

  var body: some View {
    VStack(spacing: 2) {
      HStack(alignment: .bottom) {
        Text("关联条目")
          .foregroundStyle(relations.count > 0 ? .primary : .secondary)
          .font(.title3)
        Spacer()
        if relations.count > 0 {
          NavigationLink(value: NavDestination.subjectRelationList(subjectId)) {
            Text("更多条目 »").font(.caption)
          }.buttonStyle(.navLink)
        }
      }
      Divider()
    }.padding(.top, 5)
    if relations.count == 0 {
      HStack {
        Spacer()
        Text("暂无关联条目")
          .font(.caption)
          .foregroundStyle(.secondary)
        Spacer()
      }.padding(.bottom, 5)
    }
    ScrollView(.horizontal, showsIndicators: false) {
      LazyHStack(alignment: .top) {
        ForEach(relations) { relation in
          VStack {
            Section {
              // relation.id==1 -> 改编
              if relation.relation.id > 1, !relation.relation.cn.isEmpty {
                Text(relation.relation.cn)
              } else {
                Text(relation.subject.type.description)
              }
            }
            .lineLimit(1)
            .font(.caption)
            let ctype = collections[relation.subject.id]
            ImageView(img: relation.subject.images?.resize(.r200))
              .imageStyle(width: 90, height: 90)
              .imageType(.subject)
              .imageBadge {
                if let ctype = ctype {
                  Label(ctype.description(relation.subject.type), systemImage: ctype.icon)
                    .labelStyle(.compact)
                }
              }
              .imageLink(relation.subject.link)
              .padding(2)
              .shadow(radius: 2)
            Text(relation.subject.name)
              .font(.caption)
              .multilineTextAlignment(.leading)
              .truncationMode(.middle)
              .lineLimit(2)
            Spacer()
          }.frame(width: 90, height: 160)
        }
      }.padding(.horizontal, 2)
    }.animation(.default, value: relations)
  }
}

#Preview {
  ScrollView {
    LazyVStack(alignment: .leading) {
      SubjectRelationsView(
        subjectId: Subject.previewBook.subjectId, relations: Subject.previewRelations
      )
      .modelContainer(mockContainer())
    }.padding()
  }
}
