import Foundation
import SwiftData
import SwiftUI

struct SubjectOffprintsView: View {
  let subjectId: Int
  let offprints: [SubjectRelationDTO]

  @Environment(\.modelContext) var modelContext

  @State private var collections: [Int: CollectionType] = [:]

  func load() {
    Task {
      do {
        let relationIDs = offprints.map { $0.subject.id }
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
        Text("单行本")
          .foregroundStyle(offprints.count > 0 ? .primary : .secondary)
          .font(.title3)
          .onAppear(perform: load)
        Spacer()
      }
      Divider()
    }.padding(.top, 5)
    ScrollView(.horizontal, showsIndicators: false) {
      LazyHStack(alignment: .top) {
        ForEach(offprints) { offprint in
          if let ctype = collections[offprint.subject.id] {
            ImageView(img: offprint.subject.images?.common) {
            } caption: {
              HStack {
                Image(systemName: ctype.icon)
                Spacer()
                Text(ctype.description(offprint.subject.type))
              }.padding(.horizontal, 4)
            }
            .imageStyle(width: 60, height: 80)
            .imageType(.subject)
            .imageLink(offprint.subject.link)
            .padding(2)
            .shadow(radius: 2)
          } else {
            ImageView(img: offprint.subject.images?.common)
              .imageStyle(width: 60, height: 80)
              .imageType(.subject)
              .imageLink(offprint.subject.link)
              .padding(2)
              .shadow(radius: 2)
          }
        }
      }
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
