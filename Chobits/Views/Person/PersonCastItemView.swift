import SwiftUI

struct PersonCastItemView: View {
  let item: PersonCastDTO

  var body: some View {
    HStack(alignment: .top) {
      NavigationLink(value: NavDestination.character(item.character.id)) {
        ImageView(
          img: item.character.images?.medium,
          width: 60, height: 60,
          alignment: .top, type: .person
        )
      }

      VStack(alignment: .leading) {
        NavigationLink(value: NavDestination.character(item.character.id)) {
          Text(item.character.name)
            .lineLimit(2)
        }
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
              NavigationLink(value: NavDestination.subject(relation.subject.id)) {
                Text(relation.subject.name)
                  .lineLimit(1)
              }
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
            NavigationLink(value: NavDestination.subject(relation.subject.id)) {
              ImageView(
                img: relation.subject.images?.small,
                width: 40, height: 40, alignment: .top, type: .subject
              )
            }
          }.frame(minHeight: 40)
        }
      }
    }
    .buttonStyle(.navLink)
    .frame(minHeight: 60)
  }
}
