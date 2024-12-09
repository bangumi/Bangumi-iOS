import SwiftUI

struct CharacterCastItemView: View {
  let item: CharacterCastDTO

  var body: some View {
    HStack(alignment: .top) {
      NavigationLink(value: NavDestination.subject(subjectId: item.subject.id)) {
        ImageView(
          img: item.subject.images?.common,
          width: 60, height: 60, alignment: .top,
          type: .subject, overlay: .caption
        ) {
          Text(item.type.description)
            .font(.caption)
            .foregroundStyle(.white)
        }
      }.buttonStyle(.plain)

      VStack(alignment: .leading) {
        NavigationLink(value: NavDestination.subject(subjectId: item.subject.id)) {
          Text(item.subject.name)
            .font(.footnote)
            .foregroundStyle(.linkText)
            .lineLimit(1)
          Spacer()
        }.buttonStyle(.plain)
        Label(item.subject.nameCN, systemImage: item.subject.type.icon)
          .lineLimit(1)
          .font(.footnote)
          .foregroundStyle(.secondary)
        Text(item.subject.info)
          .font(.caption)
          .lineLimit(1)
          .foregroundStyle(.secondary)
      }

      VStack(alignment: .trailing) {
        ForEach(item.actors) { person in
          NavigationLink(value: NavDestination.person(personId: person.id)) {
            HStack(alignment: .top) {
              VStack(alignment: .trailing) {
                Text(person.name)
                  .foregroundStyle(.linkText)
                  .lineLimit(1)
                Text(person.nameCN)
                  .foregroundStyle(.secondary)
                  .lineLimit(1)
              }.font(.footnote)
              ImageView(
                img: person.images?.grid,
                width: 40, height: 40, alignment: .top, type: .subject
              )
            }
          }.buttonStyle(.plain)
        }
      }

    }.frame(minHeight: 60)
  }
}
