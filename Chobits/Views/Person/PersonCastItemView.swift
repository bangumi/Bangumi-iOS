import SwiftUI

struct PersonCastItemView: View {
  let item: PersonCastDTO

  var body: some View {
    HStack(alignment: .top) {
      ImageView(img: item.character.images?.medium)
        .imageStyle(width: 60, height: 60, alignment: .top)
        .imageType(.person)
        .imageLink(item.character.link)

      VStack(alignment: .leading) {
        Text(item.character.name.withLink(item.character.link))
          .lineLimit(2)
        Text(item.character.nameCN)
          .lineLimit(1)
          .font(.footnote)
          .foregroundStyle(.secondary)
      }

      Spacer()

      VStack(alignment: .trailing) {
        ForEach(item.relations) { relation in
          HStack(alignment: .top) {
            VStack(alignment: .trailing) {
              Text(relation.subject.name.withLink(relation.subject.link))
                .lineLimit(1)
              HStack {
                if relation.subject.nameCN.isEmpty {
                  Text(relation.subject.type.description)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                } else {
                  Text(relation.subject.nameCN)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                }
                BorderView {
                  Text(relation.type.description)
                    .font(.caption)
                    .fixedSize(horizontal: true, vertical: true)
                    .foregroundStyle(.secondary)
                }
              }
              Divider()
            }.font(.footnote)
            ImageView(img: relation.subject.images?.small)
              .imageStyle(width: 40, height: 40, alignment: .top)
              .imageType(.subject)
              .imageLink(relation.subject.link)
          }.frame(minHeight: 40)
        }
      }
    }
    .buttonStyle(.navLink)
    .frame(minHeight: 60)
  }
}
