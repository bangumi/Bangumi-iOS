import SwiftUI

struct CharacterCastItemView: View {
  let item: CharacterCastDTO

  @AppStorage("titlePreference") var titlePreference: TitlePreference = .original

  var body: some View {
    CardView {
      HStack(alignment: .top) {
        ImageView(img: item.subject.images?.resize(.r200))
          .imageStyle(width: 60, height: 60, alignment: .top)
          .imageType(.subject)
          .imageCaption {
            Text(item.type.description)
          }
          .imageNavLink(item.subject.link)

        VStack(alignment: .leading) {
          Text(item.subject.title(with: titlePreference).withLink(item.subject.link))
          if let subtitle = item.subject.subtitle(with: titlePreference) {
            Text(subtitle)
              .foregroundStyle(.secondary)
          }
          Label(item.subject.type.description, systemImage: item.subject.type.icon)
            .foregroundStyle(.secondary)
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
                Text(person.title(with: titlePreference).withLink(person.link))
                if let subtitle = person.subtitle(with: titlePreference) {
                  Text(subtitle)
                    .foregroundStyle(.secondary)
                }
              }
              .lineLimit(1)
              .font(.footnote)
              ImageView(img: person.images?.grid)
                .imageStyle(width: 40, height: 40, alignment: .top)
                .imageType(.person)
                .imageNavLink(person.link)
            }
          }
        }
      }
      .buttonStyle(.navigation)
      .frame(minHeight: 60)
    }
  }
}
