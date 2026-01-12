import Foundation
import OSLog
import SwiftData
import SwiftUI

struct SubjectRecsView: View {
  let subjectId: Int
  let recs: [SubjectRecDTO]

  @AppStorage("titlePreference") var titlePreference: TitlePreference = .original

  @State private var collections: [Int: CollectionType] = [:]

  private func loadCollections() async {
    do {
      let db = try await Chii.shared.getDB()
      let ids = recs.map { $0.subject.id }
      collections = try await db.getCollectionTypes(subjectIds: ids)
    } catch {
      Logger.app.error("Failed to load collections: \(error)")
    }
  }

  var body: some View {
    Group {
      VStack(spacing: 2) {
        HStack(alignment: .bottom) {
          Text("猜你喜欢")
            .foregroundStyle(recs.count > 0 ? .primary : .secondary)
            .font(.title3)
          Spacer()
        }
        Divider()
      }.padding(.top, 5)
      if recs.count == 0 {
        HStack {
          Spacer()
          Text("暂无推荐")
            .font(.caption)
            .foregroundStyle(.secondary)
          Spacer()
        }.padding(.bottom, 5)
      }
      ScrollView(.horizontal, showsIndicators: false) {
        LazyHStack(alignment: .top) {
          ForEach(recs) { rec in
            VStack {
              ImageView(img: rec.subject.images?.resize(.r200))
                .imageCollectionStatus(ctype: collections[rec.subject.id])
                .imageStyle(width: 72, height: 72)
                .imageType(.subject)
                .imageNavLink(rec.subject.link)
                .padding(2)
                .shadow(radius: 2)
              Text(rec.subject.title(with: titlePreference))
                .multilineTextAlignment(.leading)
                .truncationMode(.middle)
                .lineLimit(2)
              Spacer()
            }
            .font(.caption)
            .frame(width: 72, height: 120)
          }
        }.padding(.horizontal, 2)
      }
      .scrollClipDisabled()
      .animation(.default, value: recs)
    }.task {
      await loadCollections()
    }
  }
}

#Preview {
  ScrollView {
    LazyVStack(alignment: .leading) {
      SubjectRecsView(
        subjectId: Subject.previewAnime.subjectId, recs: Subject.previewRecs
      )
    }.padding()
  }.modelContainer(mockContainer())
}
