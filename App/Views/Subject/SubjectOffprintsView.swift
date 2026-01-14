import Foundation
import OSLog
import SwiftData
import SwiftUI

struct SubjectOffprintsView: View {
  let subjectId: Int
  let offprints: [SubjectRelationDTO]

  @State private var collections: [Int: CollectionType] = [:]
  @State private var activeSubject: SlimSubjectDTO? = nil

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
    VStack {
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
              .contextMenu {
                Button {
                  activeSubject = offprint.subject
                } label: {
                  Label("管理收藏", systemImage: "square.and.pencil")
                }
              } preview: {
                SubjectCardView(subject: offprint.subject)
                  .padding()
                  .frame(idealWidth: 360)
              }
              .padding(2)
              .shadow(radius: 2)
          }
        }.padding(.horizontal, 2)
      }
      .scrollClipDisabled()
      .animation(.default, value: offprints)
    }
    .task {
      await loadCollections()
    }
    .onChange(of: activeSubject) { _, newValue in
      if newValue == nil {
        Task {
          await loadCollections()
        }
      }
    }
    .sheet(item: $activeSubject) { item in
      SubjectCollectionBoxView(subjectId: item.id)
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
