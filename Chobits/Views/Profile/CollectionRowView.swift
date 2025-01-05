import SwiftData
import SwiftUI

struct CollectionRowView: View {
  let collection: SlimUserSubjectCollectionDTO

  @Environment(\.modelContext) var modelContext

  var body: some View {
    HStack(alignment: .top) {
      ImageView(img: collection.subject.images?.resize(.r200))
        .imageStyle(width: 60, height: 60)
        .imageType(.subject)
        .imageLink(collection.subject.link)
      VStack(alignment: .leading) {
        Text(collection.subject.name.withLink(collection.subject.link))
          .lineLimit(1)
        Text(collection.subject.nameCN)
          .lineLimit(1)
          .font(.footnote)
          .foregroundStyle(.secondary)
        Spacer()
        HStack {
          if collection.private {
            Image(systemName: "lock.fill").foregroundStyle(.accent)
          }
          Text(collection.updatedAt.datetimeDisplay)
            .foregroundStyle(.secondary)
            .lineLimit(1)
          Spacer()
          if collection.rate > 0 {
            StarsView(score: Float(collection.rate), size: 12)
          }
        }.font(.footnote)
        if !collection.comment.isEmpty {
          VStack(alignment: .leading, spacing: 2) {
            Divider()
            Text(collection.comment)
              .padding(2)
              .font(.footnote)
              .multilineTextAlignment(.leading)
              .textSelection(.enabled)
              .foregroundStyle(.secondary)
          }
        }
      }
    }
    .buttonStyle(.navLink)
    .frame(minHeight: 60)
    .padding(2)
    .clipShape(RoundedRectangle(cornerRadius: 10))
  }
}

#Preview {
  let container = mockContainer()

  let collection = UserSubjectCollection.previewAnime
  let subject = Subject.previewAnime
  container.mainContext.insert(subject)
  container.mainContext.insert(collection)

  return ScrollView {
    LazyVStack(alignment: .leading) {
      CollectionRowView(collection: collection.slim)
    }.padding().modelContainer(container)
  }
}
