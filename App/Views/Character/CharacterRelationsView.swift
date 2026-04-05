import SwiftUI

struct CharacterRelationsView: View {
  let characterId: Int
  let relations: [CharacterRelationDTO]

  @AppStorage("titlePreference") var titlePreference: TitlePreference = .original

  var body: some View {
    VStack(spacing: 2) {
      HStack(alignment: .bottom) {
        Text("关联角色")
          .foregroundStyle(relations.count > 0 ? .primary : .secondary)
          .font(.title3)
        Spacer()
        if relations.count > 0 {
          NavigationLink(value: NavDestination.characterRelationList(characterId)) {
            Text("更多角色 »").font(.caption)
          }
          .buttonStyle(.navigation)
        }
      }
      .padding(.top, 5)

      Divider()

      if relations.isEmpty {
        HStack {
          Spacer()
          Text("暂无关联角色")
            .font(.caption)
            .foregroundStyle(.secondary)
          Spacer()
        }
        .padding(.bottom, 5)
      } else {
        ScrollView(.horizontal, showsIndicators: false) {
          LazyHStack(alignment: .top, spacing: 6) {
            ForEach(relations) { item in
              CharacterRelationCard(item: item)
            }
          }
          .padding(.horizontal, 2)
        }
        .scrollClipDisabled()
      }
    }
    .animation(.default, value: relations)
  }
}

private struct CharacterRelationCard: View {
  let item: CharacterRelationDTO

  @AppStorage("titlePreference") var titlePreference: TitlePreference = .original

  var relationText: String {
    item.relation.cn.isEmpty ? "关联" : item.relation.cn
  }

  var body: some View {
    SpoilerRevealContainer(isSpoiler: item.spoiler) {
      VStack(alignment: .leading, spacing: 2) {
        Text(relationText)
          .lineLimit(1)
          .font(.caption)
          .foregroundStyle(.secondary)
          .frame(maxWidth: .infinity, alignment: .center)
          .multilineTextAlignment(.center)

        ImageView(img: item.character.images?.resize(.r200))
          .imageStyle(width: 72, height: 72)
          .imageType(.person)
          .imageNSFW(item.character.nsfw)
          .imageNavLink(item.character.link)
          .clipShape(RoundedRectangle(cornerRadius: 8))
          .shadow(radius: 2)

        Text(item.character.title(with: titlePreference))
          .font(.caption)
          .multilineTextAlignment(.leading)
          .truncationMode(.middle)
          .lineLimit(2)

        if item.ended {
          HStack(spacing: 4) {
            Spacer(minLength: 0)
            Text("已结束")
            Spacer(minLength: 0)
          }
          .font(.caption2)
          .foregroundStyle(.secondary)
          .lineLimit(1)
        }
      }
      .padding(4)
    }
    .frame(width: 80)
  }
}

#Preview {
  NavigationStack {
    ScrollView {
      LazyVStack(alignment: .leading) {
        CharacterRelationsView(
          characterId: Character.preview.characterId,
          relations: Character.previewRelations
        )
      }
      .padding()
    }
  }
}
