import SwiftUI

struct PersonCastItemView: View {
  let item: PersonCastDTO

  @AppStorage("titlePreference") var titlePreference: TitlePreference = .original

  var body: some View {
    CardView {
      HStack(alignment: .top) {
        ImageView(img: item.character.images?.medium)
          .imageStyle(width: 60, height: 60, alignment: .top)
          .imageType(.person)
          .imageNavLink(item.character.link)

        VStack(alignment: .leading) {
          Text(item.character.title(with: titlePreference).withLink(item.character.link))
            .lineLimit(2)
          if let subtitle = item.character.subtitle(with: titlePreference) {
            Text(subtitle)
              .lineLimit(1)
              .font(.footnote)
              .foregroundStyle(.secondary)
          }
        }

        Spacer()

        VStack(alignment: .trailing) {
          ForEach(item.relations) { relation in
            HStack(alignment: .top) {
              VStack(alignment: .trailing) {
                Text(relation.subject.title(with: titlePreference).withLink(relation.subject.link))
                  .lineLimit(1)
                HStack {
                  if let subtitle = relation.subject.subtitle(with: titlePreference) {
                    Text(subtitle)
                      .foregroundStyle(.secondary)
                      .lineLimit(1)
                  } else {
                    Text(relation.subject.type.description)
                      .font(.caption)
                      .fixedSize(horizontal: true, vertical: true)
                      .foregroundStyle(.secondary)
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
                .imageNavLink(relation.subject.link)
            }.frame(minHeight: 40)
          }
        }
      }
      .buttonStyle(.navigation)
      .frame(minHeight: 60)
    }
  }
}
