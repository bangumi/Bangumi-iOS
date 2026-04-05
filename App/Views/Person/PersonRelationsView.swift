import SwiftUI

struct PersonRelationsView: View {
  let personId: Int
  let relations: [PersonRelationDTO]

  @AppStorage("titlePreference") var titlePreference: TitlePreference = .original

  var body: some View {
    VStack(spacing: 2) {
      HStack(alignment: .bottom) {
        Text("关联人物")
          .foregroundStyle(relations.count > 0 ? .primary : .secondary)
          .font(.title3)
        Spacer()
        if relations.count > 0 {
          NavigationLink(value: NavDestination.personRelationList(personId)) {
            Text("更多人物 »").font(.caption)
          }
          .buttonStyle(.navigation)
        }
      }
      .padding(.top, 5)

      Divider()

      if relations.isEmpty {
        HStack {
          Spacer()
          Text("暂无关联人物")
            .font(.caption)
            .foregroundStyle(.secondary)
          Spacer()
        }
        .padding(.bottom, 5)
      } else {
        ScrollView(.horizontal, showsIndicators: false) {
          LazyHStack(alignment: .top, spacing: 6) {
            ForEach(relations) { item in
              PersonRelationCard(item: item)
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

private struct PersonRelationCard: View {
  let item: PersonRelationDTO

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

        ImageView(img: item.person.images?.resize(.r200))
          .imageStyle(width: 72, height: 72)
          .imageType(.person)
          .imageNSFW(item.person.nsfw)
          .imageNavLink(item.person.link)
          .clipShape(RoundedRectangle(cornerRadius: 8))
          .shadow(radius: 2)

        Text(item.person.title(with: titlePreference))
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
        PersonRelationsView(
          personId: Person.preview.personId,
          relations: Person.previewRelations
        )
      }
      .padding()
    }
  }
}
