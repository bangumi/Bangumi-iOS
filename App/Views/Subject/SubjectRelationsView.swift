import Foundation
import OSLog
import SwiftData
import SwiftUI

struct SubjectRelationsView: View {
  let subjectId: Int
  let relations: [SubjectRelationDTO]

  @AppStorage("titlePreference") var titlePreference: TitlePreference = .original

  @State private var collections: [Int: CollectionType] = [:]

  private func loadCollections() async {
    do {
      let db = try await Chii.shared.getDB()
      let ids = relations.map { $0.subject.id }
      collections = try await db.getCollectionTypes(subjectIds: ids)
    } catch {
      Logger.app.error("Failed to load collections: \(error)")
    }
  }

  var body: some View {
    Group {
      VStack(spacing: 2) {
        HStack(alignment: .bottom) {
          Text("关联条目")
            .foregroundStyle(relations.count > 0 ? .primary : .secondary)
            .font(.title3)
          Spacer()
          if relations.count > 0 {
            NavigationLink(value: NavDestination.subjectRelationList(subjectId)) {
              Text("更多条目 »").font(.caption)
            }.buttonStyle(.navigation)
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
              .foregroundStyle(.secondary)
              ImageView(img: relation.subject.images?.resize(.r200))
                .imageCollectionStatus(ctype: collections[relation.subject.id])
                .imageStyle(width: 80, height: 80)
                .imageType(.subject)
                .imageNavLink(relation.subject.link)
                .padding(2)
                .shadow(radius: 2)
              Text(relation.subject.title(with: titlePreference))
                .font(.caption)
                .multilineTextAlignment(.leading)
                .truncationMode(.middle)
                .lineLimit(2)
              Spacer()
            }.frame(width: 80, height: 150)
          }
        }.padding(.horizontal, 2)
      }
      .scrollClipDisabled()
      .animation(.default, value: relations)
    }.task {
      await loadCollections()
    }
  }
}

#Preview {
  ScrollView {
    LazyVStack(alignment: .leading) {
      SubjectRelationsView(
        subjectId: Subject.previewBook.subjectId, relations: Subject.previewRelations
      )
    }.padding()
  }.modelContainer(mockContainer())
}
