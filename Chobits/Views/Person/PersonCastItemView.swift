import SwiftUI

struct PersonCastItemView: View {
  let item: PersonCastDTO

  var body: some View {
    HStack(alignment: .top) {
      NavigationLink(value: NavDestination.character(characterId: item.character.id)) {
        ImageView(
          img: item.character.images?.medium,
          width: 60, height: 60,
          alignment: .top, type: .subject
        )
      }.buttonStyle(.plain)

      VStack(alignment: .leading) {
        NavigationLink(value: NavDestination.character(characterId: item.character.id)) {
          Text(item.character.name)
            .foregroundStyle(.linkText)
            .lineLimit(2)
        }.buttonStyle(.plain)
        Text(item.character.nameCN)
          .lineLimit(1)
          .font(.footnote)
          .foregroundStyle(.secondary)
      }

      Spacer()

      VStack(alignment: .trailing) {
        ForEach(item.relations) { relation in
          NavigationLink(value: NavDestination.subject(subjectId: relation.subject.id)) {
            HStack(alignment: .top) {
              VStack(alignment: .trailing) {
                Text(relation.subject.name)
                  .foregroundStyle(.linkText)
                  .lineLimit(1)
                HStack {
                  Text(relation.subject.nameCN)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                  BorderView {
                    Text(relation.type.description)
                      .font(.caption)
                      .fixedSize(horizontal: true, vertical: true)
                      .foregroundStyle(.secondary)
                  }
                }
              }.font(.footnote)
              ImageView(
                img: relation.subject.images?.grid,
                width: 40, height: 40, alignment: .top, type: .subject
              )
            }.frame(minHeight: 40)
          }.buttonStyle(.plain)
          Divider()
        }
      }

    }.frame(minHeight: 60)
  }
}
