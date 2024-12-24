import Foundation
import SwiftData
import SwiftUI

struct SubjectRelationsView: View {
  let subjectId: Int
  let relations: [SubjectRelationDTO]

  @Environment(\.modelContext) var modelContext

  @State private var collections: [Int: CollectionType] = [:]

  func load() {
    Task {
      do {
        let relationIDs = relations.map { $0.subject.id }
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
    }
  }

  var body: some View {
    VStack(spacing: 2) {
      HStack(alignment: .bottom) {
        Text("关联条目")
          .foregroundStyle(relations.count > 0 ? .primary : .secondary)
          .font(.title3)
          .onAppear(perform: load)
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
            if let ctype = collections[relation.subject.id] {
              ImageView(img: relation.subject.images?.common) {
              } caption: {
                HStack {
                  Image(systemName: ctype.icon)
                  Spacer()
                  Text(ctype.description(relation.subject.type))
                }.padding(.horizontal, 4)
              }
              .imageStyle(width: 90, height: 120)
              .imageType(.subject)
              .imageLink(relation.subject.link)
              .padding(2)
              .shadow(radius: 2)
            } else {
              ImageView(img: relation.subject.images?.common)
                .imageStyle(width: 90, height: 120)
                .imageType(.subject)
                .imageLink(relation.subject.link)
                .padding(2)
                .shadow(radius: 2)
            }
            Text(relation.subject.name)
              .font(.caption)
              .multilineTextAlignment(.leading)
              .truncationMode(.middle)
              .lineLimit(2)
            Spacer()
          }.frame(width: 90, height: 190)
        }
      }
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
