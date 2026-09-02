import SwiftUI

struct CharacterSmallView: View {
  @AppStorage("titlePreference") var titlePreference: TitlePreference = .original

  let character: SlimCharacterDTO
  let isCollected: Bool

  var body: some View {
    EmbedCard {
      HStack {
        ImageView(img: character.images?.resize(.r200))
          .imageStyle(width: 50, height: 50, alignment: .top)
          .imageType(.person)
          .imageNSFW(character.nsfw)
          .imageCollectedStatus(isCollected)
        VStack(alignment: .leading) {
          Text(character.title(with: titlePreference))
          if let info = character.info, !info.isEmpty {
            Text(info)
              .font(.footnote)
              .foregroundStyle(.secondary)
          }
        }.lineLimit(1)
        Spacer(minLength: 0)
      }
    }
    .frame(height: 58)
  }

  init(character: SlimCharacterDTO, isCollected: Bool = false) {
    self.character = character
    self.isCollected = isCollected
  }
}
