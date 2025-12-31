import Foundation
import SwiftData
import SwiftUI

struct SubjectRecsView: View {
  let subjectId: Int
  let recs: [SubjectRecDTO]

  @AppStorage("titlePreference") var titlePreference: TitlePreference = .original

  @Environment(\.modelContext) var modelContext

  @Query private var collects: [Subject]

  init(subjectId: Int, recs: [SubjectRecDTO]) {
    self.subjectId = subjectId
    self.recs = recs
    let recIDs = recs.map { $0.subject.id }
    let descriptor = FetchDescriptor<Subject>(
      predicate: #Predicate<Subject> {
        recIDs.contains($0.subjectId)
      })
    _collects = Query(descriptor)
  }

  var collections: [Int: CollectionType] {
    collects.reduce(into: [:]) { $0[$1.subjectId] = $1.ctypeEnum }
  }

  var body: some View {
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
            let ctype = collections[rec.subject.id] ?? .none
            ImageView(img: rec.subject.images?.resize(.r200))
              .imageStyle(width: 72, height: 72)
              .imageType(.subject)
              .imageBadge(show: ctype != .none) {
                Label(ctype.description(rec.subject.type), systemImage: ctype.icon)
                  .labelStyle(.compact)
              }
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
    }.animation(.default, value: recs)
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
