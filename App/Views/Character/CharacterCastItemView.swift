import SwiftUI

struct CharacterCastItemView: View {
  let item: CharacterCastDTO

  var body: some View {
    HStack(alignment: .top) {
      ImageView(img: item.subject.images?.resize(.r200))
        .imageStyle(width: 60, height: 60, alignment: .top)
        .imageType(.subject)
        .imageCaption {
          Text(item.type.description)
        }
        .imageLink(item.subject.link)

      VStack(alignment: .leading) {
        Text(item.subject.name.withLink(item.subject.link))
        if item.subject.nameCN.isEmpty {
          Label(item.subject.type.description, systemImage: item.subject.type.icon)
            .foregroundStyle(.secondary)
        } else {
          Label(item.subject.nameCN, systemImage: item.subject.type.icon)
            .foregroundStyle(.secondary)
        }
        Text(item.subject.info ?? "")
          .font(.caption)
          .foregroundStyle(.secondary)
      }
      .lineLimit(1)
      .font(.footnote)

      Spacer()

      VStack(alignment: .trailing) {
        ForEach(item.actors) { person in
          HStack(alignment: .top) {
            VStack(alignment: .trailing) {
              Text(person.name.withLink(person.link))
              Text(person.nameCN)
                .foregroundStyle(.secondary)
            }
            .lineLimit(1)
            .font(.footnote)
            ImageView(img: person.images?.grid)
              .imageStyle(width: 40, height: 40, alignment: .top)
              .imageType(.person)
              .imageLink(person.link)
          }
        }
      }
    }
    .buttonStyle(.navigation)
    .frame(minHeight: 60)
  }
}
