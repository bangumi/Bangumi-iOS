import Foundation
import SwiftData
import SwiftUI

struct SubjectOffprintsView: View {
  let subjectId: Int
  let offprints: [SubjectRelationDTO]

  @Environment(\.modelContext) var modelContext

  @Query private var collects: [Subject]

  init(subjectId: Int, offprints: [SubjectRelationDTO]) {
    self.subjectId = subjectId
    self.offprints = offprints
    let offprintIDs = offprints.map { $0.subject.id }
    let descriptor = FetchDescriptor<Subject>(
      predicate: #Predicate<Subject> {
        offprintIDs.contains($0.subjectId)
      })
    _collects = Query(descriptor)
  }

  var collections: [Int: CollectionType] {
    collects.reduce(into: [:]) { $0[$1.subjectId] = $1.ctypeEnum }
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 2) {
      Text("单行本")
        .foregroundStyle(offprints.count > 0 ? .primary : .secondary)
        .font(.title3)
      Divider()
    }.padding(.top, 5)
    ScrollView(.horizontal, showsIndicators: false) {
      LazyHStack(alignment: .top) {
        ForEach(offprints) { offprint in
          let ctype = collections[offprint.subject.id] ?? .none
          ImageView(img: offprint.subject.images?.resize(.r200))
            .imageStyle(width: 60, height: 80)
            .imageType(.subject)
            .imageBadge(show: ctype != .none) {
              Label(ctype.description(offprint.subject.type), systemImage: ctype.icon)
                .labelStyle(.compact)
            }
            .imageNavLink(offprint.subject.link)
            .padding(2)
            .shadow(radius: 2)
        }
      }.padding(.horizontal, 2)
    }.animation(.default, value: offprints)
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
