import SwiftData
import SwiftUI

struct SubjectCharactersView: View {
  let subjectId: Int
  let characters: [SubjectCharacterDTO]

  @AppStorage("isolationMode") var isolationMode: Bool = false

  var body: some View {
    VStack(spacing: 2) {
      HStack(alignment: .bottom) {
        Text("角色介绍")
          .foregroundStyle(characters.count > 0 ? .primary : .secondary)
          .font(.title3)
        Spacer()
        if characters.count > 0 {
          NavigationLink(value: NavDestination.subjectCharacterList(subjectId)) {
            Text("更多角色 »").font(.caption)
          }.buttonStyle(.navigation)
        }
      }
      .padding(.top, 5)

      Divider()

      if characters.count == 0 {
        HStack {
          Spacer()
          Text("暂无角色")
            .font(.caption)
            .foregroundStyle(.secondary)
          Spacer()
        }.padding(5)
      } else {
        ScrollView(.horizontal, showsIndicators: false) {
          HStack(spacing: 4) {
            ForEach(characters, id: \.character.id) { item in
              CharacterCard(item: item, isolationMode: isolationMode)
            }
          }
        }
      }
    }
    .animation(.default, value: characters)
  }
}

struct CharacterCard: View {
  let item: SubjectCharacterDTO
  let isolationMode: Bool

  var body: some View {
    VStack(alignment: .leading, spacing: 2) {
      // Character Image
      ImageView(img: item.character.images?.medium)
        .imageStyle(width: 72, height: 108, alignment: .top)
        .imageType(.person)
        .imageLink(item.character.link)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .shadow(radius: 2)

      // Character Name
      Text(item.character.name.withLink(item.character.link))
        .font(.footnote)
        .fontWeight(.medium)
        .lineLimit(2)
        .multilineTextAlignment(.leading)

      // Role and Comment
      HStack {
        BorderView(padding: 2) {
          Text(item.type.description)
            .foregroundStyle(.secondary)
        }
        if let comment = item.character.comment, comment > 0, !isolationMode {
          Text("(+\(comment))")
            .lineLimit(1)
            .foregroundStyle(.accent)
        }
        Spacer(minLength: 0)
      }.font(.caption)

      // CV Information
      if let actor = item.actors.first {
        Text("CV \(actor.name.withLink(actor.link))")
          .font(.caption)
          .foregroundStyle(.secondary)
          .lineLimit(1)
      }

      Spacer()
    }
    .padding(4)
    .frame(width: 80)
  }
}

#Preview {
  NavigationStack {
    ScrollView {
      LazyVStack(alignment: .leading) {
        SubjectCharactersView(
          subjectId: Subject.previewAnime.subjectId,
          characters: Subject.previewCharacters)
      }.padding()
    }
  }
}
