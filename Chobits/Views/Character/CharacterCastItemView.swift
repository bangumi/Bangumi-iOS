import SwiftUI

struct CharacterCastItemView: View {
  let item: CharacterCastDTO

  var body: some View {
    HStack(alignment: .top) {
      NavigationLink(value: NavDestination.subject(item.subject.id)) {
        ImageView(img: item.subject.images?.common) {
        } caption: {
          Text(item.type.description)
        }
        .imageStyle(width: 60, height: 60, alignment: .top)
        .imageType(.subject)
      }

      VStack(alignment: .leading) {
        NavigationLink(value: NavDestination.subject(item.subject.id)) {
          Text(item.subject.name)
        }
        if item.subject.nameCN.isEmpty {
          Label(item.subject.type.description, systemImage: item.subject.type.icon)
            .foregroundStyle(.secondary)
        } else {
          Label(item.subject.nameCN, systemImage: item.subject.type.icon)
            .foregroundStyle(.secondary)
        }
        Text(item.subject.info)
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
              NavigationLink(value: NavDestination.person(person.id)) {
                Text(person.name)
              }
              Text(person.nameCN)
                .foregroundStyle(.secondary)
            }
            .lineLimit(1)
            .font(.footnote)
            NavigationLink(value: NavDestination.person(person.id)) {
              ImageView(img: person.images?.grid) {
              } caption: {
                Text("Actor")
              }
              .imageStyle(width: 40, height: 40, alignment: .top)
              .imageType(.person)
            }
          }
        }
      }
    }
    .buttonStyle(.navLink)
    .frame(minHeight: 60)
  }
}
