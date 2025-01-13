import Foundation
import SwiftData
import SwiftUI

struct SubjectOffprintsView: View {
  let subjectId: Int
  let offprints: [SubjectRelationDTO]

  @Environment(\.modelContext) var modelContext

  @Query private var collects: [UserSubjectCollection]

  init(subjectId: Int, offprints: [SubjectRelationDTO]) {
    self.subjectId = subjectId
    self.offprints = offprints
    let offprintIDs = offprints.map { $0.subject.id }
    let descriptor = FetchDescriptor<UserSubjectCollection>(
      predicate: #Predicate<UserSubjectCollection> {
        offprintIDs.contains($0.subjectId)
      })
    _collects = Query(descriptor)
  }

  var collections: [Int: CollectionType] {
    collects.reduce(into: [:]) { $0[$1.subjectId] = $1.typeEnum }
  }

  var body: some View {
    VStack(spacing: 2) {
      HStack(alignment: .bottom) {
        Text("单行本")
          .foregroundStyle(offprints.count > 0 ? .primary : .secondary)
          .font(.title3)
        Spacer()
      }
      Divider()
    }.padding(.top, 5)
    ScrollView(.horizontal, showsIndicators: false) {
      LazyHStack(alignment: .top) {
        ForEach(offprints) { offprint in
          let ctype = collections[offprint.subject.id]
          ImageView(img: offprint.subject.images?.resize(.r200))
            .imageStyle(width: 60, height: 80)
            .imageType(.subject)
            .imageCaption(show: ctype != nil) {
              HStack {
                Image(systemName: ctype?.icon ?? "")
                Spacer()
                Text(ctype?.description(offprint.subject.type) ?? "")
              }.padding(.horizontal, 4)
            }
            .imageLink(offprint.subject.link)
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
      ).modelContainer(mockContainer())
    }.padding()
  }
}
