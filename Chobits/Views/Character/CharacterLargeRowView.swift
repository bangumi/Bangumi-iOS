import SwiftUI

struct CharacterLargeRowView: View {
  @Environment(Character.self) private var character

  var body: some View {
    HStack(spacing: 8) {
      ImageView(img: character.images?.resize(.r200))
        .imageStyle(width: 90, height: 90)
        .imageType(.person)
        .imageNSFW(character.nsfw)
        .imageLink(character.link)
      VStack(alignment: .leading, spacing: 4) {
        Text(character.name)
          .font(.headline)
          .lineLimit(1)
        if !character.nameCN.isEmpty {
          Text(character.nameCN)
            .font(.subheadline)
            .foregroundStyle(.secondary)
            .lineLimit(1)
        }
        Label(character.roleEnum.description, systemImage: character.roleEnum.icon)
          .foregroundStyle(.secondary)
          .font(.footnote)
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
