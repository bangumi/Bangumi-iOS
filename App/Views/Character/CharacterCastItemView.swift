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
          ForEach(item.casts) { cast in
            HStack(alignment: .top) {
              VStack(alignment: .trailing, spacing: 2) {
                Text(cast.person.title(with: titlePreference).withLink(cast.person.link))
                if let subtitle = cast.person.subtitle(with: titlePreference) {
                  Text(subtitle)
                    .foregroundStyle(.secondary)
                }
                HStack(spacing: 4) {
                  BorderView {
                    Text(cast.relation.description).font(.caption)
                  }
                  if !cast.summary.isEmpty {
                    Text(cast.summary)
                      .font(.caption)
                      .lineLimit(1)
                  }
                }
                .foregroundStyle(.secondary)
              }
              .lineLimit(1)
              .font(.footnote)
              ImageView(img: cast.person.images?.grid)
                .imageStyle(width: 40, height: 40, alignment: .top)
                .imageType(.person)
                .imageNavLink(cast.person.link)
            }
          }
        }
      }
      .buttonStyle(.navigation)
      .frame(minHeight: 60)
    }
  }
}
