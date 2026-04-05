import SwiftUI

struct CharacterRelationItemView: View {
  let item: CharacterRelationDTO

  @AppStorage("titlePreference") var titlePreference: TitlePreference = .original

  var relationText: String {
    item.relation.cn.isEmpty ? "关联" : item.relation.cn
  }

  var body: some View {
    SpoilerRevealContainer(isSpoiler: item.spoiler) {
      CardView {
        HStack(alignment: .top) {
          ImageView(img: item.character.images?.resize(.r200))
            .imageStyle(width: 60, height: 60, alignment: .top)
            .imageType(.person)
            .imageNSFW(item.character.nsfw)
            .imageNavLink(item.character.link)

          VStack(alignment: .leading, spacing: 4) {
            Text(item.character.title(with: titlePreference).withLink(item.character.link))
              .lineLimit(1)
            if let subtitle = item.character.subtitle(with: titlePreference) {
              Text(subtitle)
                .font(.footnote)
                .foregroundStyle(.secondary)
                .lineLimit(1)
            }

            HStack(spacing: 4) {
              Label(relationText, systemImage: "link")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .lineLimit(1)
              if item.ended {
                BorderView(color: .secondary.opacity(0.3), padding: 2, cornerRadius: 8) {
                  Text("已结束")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }
              }
            }

            if !item.comment.isEmpty {
              Text(item.comment)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(2)
            }
          }

          Spacer()
        }
        .buttonStyle(.navigation)
        .frame(minHeight: 60)
      }
    }
  }
}
