import SwiftUI

struct CharacterSmallView: View {
  let character: SlimCharacterDTO

  var title: String {
    if character.nameCN.isEmpty {
      return character.name
    } else {
      return character.nameCN
    }
  }

  var body: some View {
    BorderView(color: .secondary.opacity(0.2), padding: 4, paddingRatio: 1, cornerRadius: 8) {
      HStack {
        ImageView(img: character.images?.resize(.r200))
          .imageStyle(width: 50, height: 50)
          .imageType(.person)
          .imageNSFW(character.nsfw)
        VStack(alignment: .leading) {
          Text(title)
          if let info = character.info, !info.isEmpty {
            Text(info)
              .font(.footnote)
              .foregroundStyle(.secondary)
          }
        }.lineLimit(1)
        Spacer(minLength: 0)
      }
    }
    .background(.secondary.opacity(0.01))
    .clipShape(RoundedRectangle(cornerRadius: 8))
    .frame(height: 58)
  }
}
