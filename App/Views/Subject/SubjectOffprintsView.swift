import Foundation
import OSLog
import SwiftData
import SwiftUI

struct SubjectOffprintsView: View {
  let subjectId: Int
  let offprints: [SubjectRelationDTO]

  @State private var collections: [Int: CollectionType] = [:]

  private func loadCollections() async {
    do {
      let db = try await Chii.shared.getDB()
      let ids = offprints.map { $0.subject.id }
      collections = try await db.getCollectionTypes(subjectIds: ids)
    } catch {
      Logger.app.error("Failed to load collections: \(error)")
    }
  }

  var body: some View {
    Group {
      VStack(alignment: .leading, spacing: 2) {
        Text("单行本")
          .foregroundStyle(offprints.count > 0 ? .primary : .secondary)
          .font(.title3)
        Divider()
      }.padding(.top, 5)
      ScrollView(.horizontal, showsIndicators: false) {
        LazyHStack(alignment: .top) {
          ForEach(offprints) { offprint in
            ImageView(img: offprint.subject.images?.resize(.r200))
              .imageCollectionStatus(ctype: collections[offprint.subject.id])
              .imageStyle(width: 60, height: 80)
              .imageType(.subject)
              .imageNavLink(offprint.subject.link)
              .padding(2)
              .shadow(radius: 2)
          }
        }.padding(.horizontal, 2)
      }.animation(.default, value: offprints)
    }.task {
      await loadCollections()
    }
  }
}

#Preview {
  ScrollView {
    LazyVStack(alignment: .leading) {
      SubjectOffprintsView(
        subjectId: Subject.previewBook.subjectId, offprints: Subject.previewOffprints
      )
    }.padding()
  }.modelContainer(mockContainer())
}
