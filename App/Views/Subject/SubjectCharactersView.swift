import SwiftData
import SwiftUI

struct SubjectCharactersView: View {
  let subjectId: Int
  let characters: [SubjectCharacterDTO]

  @AppStorage("isolationMode") var isolationMode: Bool = false
  @AppStorage("titlePreference") var titlePreference: TitlePreference = .original

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
        .scrollClipDisabled()
      }
    }
    .animation(.default, value: characters)
  }
}

struct CharacterCard: View {
  let item: SubjectCharacterDTO
  let isolationMode: Bool

  @AppStorage("titlePreference") var titlePreference: TitlePreference = .original

  var body: some View {
    VStack(alignment: .leading, spacing: 2) {
      ImageView(img: item.character.images?.medium)
        .imageStyle(width: 72, height: 108, alignment: .top)
        .imageType(.person)
        .imageNavLink(item.character.link)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .shadow(radius: 2)

      Text(item.character.title(with: titlePreference).withLink(item.character.link))
        .font(.footnote)
        .fontWeight(.medium)
        .lineLimit(2)
        .multilineTextAlignment(.leading)

      HStack(spacing: 2) {
        BorderView(color: .secondary.opacity(0.3), padding: 2, cornerRadius: 8) {
          Text(item.type.description).foregroundStyle(.secondary)
        }
        if let comment = item.character.comment, comment > 0, !isolationMode {
          Text("(+\(comment))")
            .lineLimit(1)
            .foregroundStyle(.accent)
        }
      }.font(.caption)

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
