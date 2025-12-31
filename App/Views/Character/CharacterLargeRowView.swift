import SwiftData
import SwiftUI

struct CharacterLargeRowView: View {
  @AppStorage("titlePreference") var titlePreference: TitlePreference = .original

  @Bindable var character: Character

  var body: some View {
    HStack(spacing: 8) {
      ImageView(img: character.images?.resize(.r200))
        .imageStyle(width: 90, height: 90)
        .imageType(.person)
        .imageNSFW(character.nsfw)
        .imageNavLink(character.link)
      VStack(alignment: .leading, spacing: 4) {
        Text(character.title(with: titlePreference))
          .font(.headline)
          .lineLimit(1)
        if let subtitle = character.subtitle(with: titlePreference) {
          Text(subtitle)
            .font(.subheadline)
            .foregroundStyle(.secondary)
            .lineLimit(1)
        }
        Text(character.info)
          .font(.footnote)
          .foregroundStyle(.secondary)
          .lineLimit(2)
        if character.comment > 0 {
          Label("评论: \(character.comment)", systemImage: "bubble")
            .font(.footnote)
            .foregroundStyle(.secondary)
        }
      }
      Spacer()
    }
  }
}
