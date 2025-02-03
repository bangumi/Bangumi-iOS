import SwiftData
import SwiftUI

struct CollectionRowView: View {
  @Environment(Subject.self) var subject

  @Environment(\.modelContext) var modelContext

  var body: some View {
    HStack(alignment: .top) {
      ImageView(img: subject.images?.resize(.r200))
        .imageStyle(width: 60, height: 60)
        .imageType(.subject)
        .imageLink(subject.link)
      VStack(alignment: .leading) {
        Text(subject.name.withLink(subject.link))
          .lineLimit(1)
        Text(subject.nameCN)
          .lineLimit(1)
          .font(.footnote)
          .foregroundStyle(.secondary)
        Spacer()
        if let interest = subject.interest {
          HStack {
            if interest.private {
              Image(systemName: "lock.fill").foregroundStyle(.accent)
            }
            Text(interest.updatedAt.datetimeDisplay)
              .foregroundStyle(.secondary)
              .lineLimit(1)
            Spacer()
            if interest.rate > 0 {
              StarsView(score: Float(interest.rate), size: 12)
            }
          }.font(.footnote)
          if !interest.comment.isEmpty {
            VStack(alignment: .leading, spacing: 2) {
              Divider()
              Text(interest.comment)
                .padding(2)
                .font(.footnote)
                .multilineTextAlignment(.leading)
                .textSelection(.enabled)
            }
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

  let subject = Subject.previewAnime
  container.mainContext.insert(subject)

  return ScrollView {
    LazyVStack(alignment: .leading) {
      CollectionRowView()
        .environment(subject)
    }.padding().modelContainer(container)
  }
}
