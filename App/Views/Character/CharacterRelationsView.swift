import OSLog
import SwiftUI

struct CharacterRelationsView: View {
  let characterId: Int
  let relations: [CharacterRelationDTO]

  @AppStorage("titlePreference") var titlePreference: TitlePreference = .original
  @State private var collectionStatuses: [Int: Bool] = [:]

  private var collectionCharacterIds: [Int] {
    relations.map { $0.character.id }
  }

  private func loadCollections() async {
    do {
      let db = try await AppContext.shared.getDB()
      collectionStatuses = try await db.characterCollectionStatuses(
        characterIds: collectionCharacterIds)
    } catch {
      Logger.app.error("Failed to load character collection statuses: \(error)")
    }
  }

  private func handleMonoCollectionInvalidation(_ notification: Notification) {
    guard let characterId = MonoCollectionInvalidation.characterId(from: notification),
      collectionCharacterIds.contains(characterId)
    else {
      return
    }
    Task {
      await loadCollections()
    }
  }

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
              CharacterRelationCard(
                item: item,
                isCollected: collectionStatuses[item.character.id] ?? false
              )
            }
          }
          .padding(.horizontal, 2)
        }
        .scrollClipDisabled()
      }
    }
    .animation(.default, value: relations)
    .task(id: collectionCharacterIds) {
      await loadCollections()
    }
    .onReceive(
      NotificationCenter.default.publisher(for: MonoCollectionInvalidation.notificationName),
      perform: handleMonoCollectionInvalidation
    )
    .onAppear {
      Task {
        await loadCollections()
      }
    }
  }
}

private struct CharacterRelationCard: View {
  let item: CharacterRelationDTO
  let isCollected: Bool

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
          .imageStyle(width: 72, height: 72, cornerRadius: 8, alignment: .top)
          .imageType(.person)
          .imageNSFW(item.character.nsfw)
          .shadow(radius: 2)
          .imageCollectedStatus(isCollected)
          .imageNavLink(item.character.link)

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
