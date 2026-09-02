import OSLog
import SwiftUI

struct GlassCharacterDetailView: View {
  let character: CharacterDTO
  let detail: CharacterDetailDTO
  let reload: () async -> Void

  @AppStorage("isolationMode") private var isolationMode = false

  @Environment(\.theme) private var theme
  @State private var updating: Bool = false

  private var collected: Bool {
    (character.collectedAt ?? 0) != 0
  }

  private var subname: String {
    character.nameCN.isEmpty ? character.name : character.nameCN
  }

  func collect() async {
    updating = true
    defer { updating = false }
    do {
      if character.collectedAt ?? 0 == 0 {
        try await CharacterRepository.collectCharacter(character.id)
      } else {
        try await CharacterRepository.uncollectCharacter(character.id)
      }
      await reload()
      UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    } catch {
      Notifier.shared.alert(error: error)
    }
  }

  private var headerCard: some View {
    CardView(padding: theme.metrics.cardPadding, role: .strong) {
      VStack(alignment: .leading, spacing: 11) {
        Text(character.name)
          .font(.title3.weight(.bold))
          .foregroundStyle(theme.title)
          .textSelection(.enabled)
        HStack(alignment: .top, spacing: 12) {
          ImageView(img: character.images?.resize(.r400))
            .imageStyle(width: 104, height: 146, alignment: .top)
            .imageType(.person)
            .imageNSFW(character.nsfw)
            .enableImagePreview(
              character.images?.large,
              zoomID: ZoomNavigationID(type: .character, id: character.id)
            )
          VStack(alignment: .leading, spacing: 7) {
            HStack(spacing: 6) {
              GlassMonoTag(text: character.role.description, tone: .accent)
              if character.lock {
                GlassMonoTag(text: "锁定")
              }
              Spacer(minLength: 0)
              Button {
                Task {
                  await collect()
                }
              } label: {
                HeartView(collected: collected, updating: updating)
              }
              .buttonStyle(.explode)
            }
            Text(subname)
              .font(.footnote.weight(.bold))
              .foregroundStyle(theme.cardTitle)
              .truncationMode(.middle)
              .lineLimit(2)
              .textSelection(.enabled)
            NavigationLink(value: NavDestination.infobox("角色信息", character.infobox)) {
              HStack(alignment: .top, spacing: 4) {
                Text(character.info)
                  .font(.caption)
                  .foregroundStyle(theme.secondaryText)
                  .multilineTextAlignment(.leading)
                  .lineLimit(2)
                Spacer(minLength: 0)
                Image(systemName: "chevron.right")
                  .font(.caption2.weight(.bold))
                  .foregroundStyle(theme.disabled)
              }
            }
            .buttonStyle(.plain)
            Spacer(minLength: 0)
            HStack(spacing: 8) {
              GlassMonoCaption(text: "\(character.collects) 人收藏")
              Spacer(minLength: 0)
              if !isolationMode {
                CommentListNavigationLink(
                  route: CommentListRoute(parent: .character(character.id)),
                  count: character.comment
                )
              }
            }
          }
          .frame(minHeight: 146, alignment: .top)
        }
      }
      .frame(maxWidth: .infinity, alignment: .leading)
    }
  }

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: theme.metrics.listSpacing) {
        headerCard
        GlassInfoboxCard(title: "角色信息", infobox: character.infobox)
        GlassSummaryCard(summary: character.summary)
        GlassMonoSection(
          title: "出演作品", systemImage: "film.stack",
          destination: detail.casts.isEmpty ? nil : NavDestination.characterCastList(character.id),
          moreTitle: "更多出演 »", isEmpty: detail.casts.isEmpty,
          emptyTitle: "暂无出演", emptyDescription: "还没有关联的出演作品"
        ) {
          VStack(spacing: theme.metrics.listSpacing) {
            ForEach(detail.casts, id: \.subject.id) { item in
              GlassCharacterCastCard(item: item)
            }
          }
        }
        GlassCharacterRelationsSection(
          characterId: character.id, relations: detail.relations)
        GlassMonoSection(
          title: "相关目录", systemImage: "list.bullet.rectangle.portrait",
          destination: detail.indexes.isEmpty
            ? nil : NavDestination.characterIndexList(character.id),
          moreTitle: "更多目录 »", isEmpty: detail.indexes.isEmpty,
          emptyTitle: "暂无相关目录", emptyDescription: "还没有目录收录该角色"
        ) {
          GlassIndexRowsCard(indexes: detail.indexes)
        }
      }
      .padding(.horizontal, theme.metrics.screenPadding)
      .padding(.vertical, 12)
    }
  }
}

struct GlassCharacterCastCard: View {
  let item: CharacterCastDTO

  @AppStorage("titlePreference") var titlePreference: TitlePreference = .original

  @Environment(\.theme) private var theme

  var body: some View {
    CardView(padding: theme.metrics.cardPadding) {
      VStack(alignment: .leading, spacing: 10) {
        HStack(alignment: .top, spacing: 10) {
          ImageView(img: item.subject.images?.resize(.r200))
            .imageStyle(width: 46, height: 64)
            .imageType(.subject)
            .imageNSFW(item.subject.nsfw)
            .imageNavLink(item.subject.link)
          VStack(alignment: .leading, spacing: 5) {
            Text(
              item.subject.title(with: titlePreference)
                .withLink(item.subject.link, linkColor: theme.link)
            )
            .font(.footnote.weight(.bold))
            .lineLimit(2)
            HStack(spacing: 6) {
              GlassTypeBadge(type: item.subject.type)
              GlassMonoTag(text: item.type.description, tone: .accent)
              Spacer(minLength: 0)
            }
            if let info = item.subject.info, !info.isEmpty {
              Text(info)
                .font(.caption2)
                .foregroundStyle(theme.tertiaryText)
                .lineLimit(1)
            }
          }
          Spacer(minLength: 0)
        }
        if !item.casts.isEmpty {
          ThemedDivider()
          VStack(spacing: 8) {
            ForEach(item.casts) { cast in
              HStack(spacing: 8) {
                ImageView(img: cast.person.images?.resize(.r200))
                  .imageStyle(width: 30, height: 30)
                  .imageType(.person)
                  .imageNavLink(cast.person.link)
                VStack(alignment: .leading, spacing: 2) {
                  Text(
                    cast.person.title(with: titlePreference)
                      .withLink(cast.person.link, linkColor: theme.link)
                  )
                  .font(.caption.weight(.semibold))
                  .lineLimit(1)
                  if !cast.summary.isEmpty {
                    Text(cast.summary)
                      .font(.caption2)
                      .foregroundStyle(theme.tertiaryText)
                      .lineLimit(1)
                  }
                }
                Spacer(minLength: 0)
                GlassMonoTag(text: cast.relation.description)
              }
            }
          }
        }
      }
      .frame(maxWidth: .infinity, alignment: .leading)
    }
  }
}

struct GlassCharacterRelationsSection: View {
  let characterId: Int
  let relations: [CharacterRelationDTO]

  @Environment(\.theme) private var theme
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
    GlassMonoSection(
      title: "关联角色", systemImage: "person.2",
      destination: relations.isEmpty ? nil : NavDestination.characterRelationList(characterId),
      moreTitle: "更多角色 »", isEmpty: relations.isEmpty,
      emptyTitle: "暂无关联角色", emptyDescription: "还没有关联的其他角色"
    ) {
      ScrollView(.horizontal, showsIndicators: false) {
        LazyHStack(alignment: .top, spacing: 9) {
          ForEach(relations) { item in
            GlassCharacterRelationTile(
              item: item,
              isCollected: collectionStatuses[item.character.id] ?? false
            )
          }
        }
        .padding(.horizontal, 2)
        .padding(.vertical, 4)
      }
      .scrollClipDisabled()
    }
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

struct GlassCharacterRelationTile: View {
  let item: CharacterRelationDTO
  let isCollected: Bool

  @AppStorage("titlePreference") var titlePreference: TitlePreference = .original

  private var relationText: String {
    item.relation.cn.isEmpty ? "关联" : item.relation.cn
  }

  var body: some View {
    SpoilerRevealContainer(isSpoiler: item.spoiler) {
      GlassMonoPortraitTile(
        image: item.character.images?.resize(.r200),
        nsfw: item.character.nsfw,
        isCollected: isCollected,
        link: item.character.link,
        caption: relationText,
        title: item.character.title(with: titlePreference),
        footnote: item.ended ? "已结束" : nil
      )
    }
  }
}

struct GlassCharacterRelationCard: View {
  let item: CharacterRelationDTO
  let isCollected: Bool

  @AppStorage("titlePreference") var titlePreference: TitlePreference = .original

  @Environment(\.theme) private var theme

  private var relationText: String {
    item.relation.cn.isEmpty ? "关联" : item.relation.cn
  }

  var body: some View {
    SpoilerRevealContainer(isSpoiler: item.spoiler) {
      CardView(padding: theme.metrics.cardPadding) {
        HStack(alignment: .top, spacing: 10) {
          ImageView(img: item.character.images?.resize(.r200))
            .imageStyle(width: 56, height: 56, alignment: .top)
            .imageType(.person)
            .imageNSFW(item.character.nsfw)
            .imageCollectedStatus(isCollected)
            .imageNavLink(item.character.link)
          VStack(alignment: .leading, spacing: 5) {
            Text(
              item.character.title(with: titlePreference)
                .withLink(item.character.link, linkColor: theme.link)
            )
            .font(.footnote.weight(.bold))
            .lineLimit(1)
            HStack(spacing: 6) {
              GlassMonoTag(text: relationText, tone: .accent)
              if item.ended {
                GlassMonoTag(text: "已结束")
              }
              Spacer(minLength: 0)
            }
            if !item.comment.isEmpty {
              Text(item.comment)
                .font(.caption2)
                .foregroundStyle(theme.tertiaryText)
                .lineLimit(2)
            }
          }
          Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
      }
    }
  }
}

struct GlassCharacterCastListView: View {
  let characterId: Int

  @Environment(\.theme) private var theme
  @State private var type: CastType = .none
  @State private var reloader = false

  func load(limit: Int, offset: Int) async -> PagedDTO<CharacterCastDTO>? {
    do {
      let resp = try await CharacterService.getCharacterCasts(
        characterId, type: type, limit: limit, offset: offset)
      return resp
    } catch {
      Notifier.shared.alert(error: error)
    }
    return nil
  }

  var body: some View {
    VStack(spacing: 0) {
      GlassCastTypeChips(selected: $type) {
        withAnimation(.default) {
          reloader.toggle()
        }
      }
      .padding(.horizontal, theme.metrics.screenPadding)
      .padding(.vertical, 6)
      ScrollView {
        OffsetPagedView<CharacterCastDTO, _>(reloader: reloader, nextPageFunc: load) { item in
          GlassCharacterCastCard(item: item)
        }
        .padding(.horizontal, theme.metrics.screenPadding)
        .padding(.bottom, 12)
      }
    }
  }
}

struct GlassCastTypeChips: View {
  @Binding var selected: CastType
  let onChange: () -> Void

  var body: some View {
    ScrollView(.horizontal, showsIndicators: false) {
      HStack(spacing: 8) {
        ForEach(CastType.allCases) { ct in
          GlassChip(title: ct.description, isSelected: selected == ct) {
            selected = ct
            onChange()
          }
        }
      }
      .padding(.horizontal, 2)
      .padding(.vertical, 3)
    }
    .scrollClipDisabled()
  }
}

struct GlassCharacterRelationListView: View {
  let characterId: Int

  @Environment(\.theme) private var theme
  @State private var reloader = false
  @State private var collectionStatuses: [Int: Bool] = [:]
  @State private var loadedCharacterIds: Set<Int> = []

  private func loadCollectionStatuses(characterIds: [Int]) async {
    guard !characterIds.isEmpty else { return }
    do {
      guard let db = await AppContext.shared.databaseIfAvailable() else { return }
      let statuses = try await db.characterCollectionStatuses(characterIds: characterIds)
      collectionStatuses.merge(statuses) { _, new in new }
    } catch {
      Logger.app.error("Failed to load character collection statuses: \(error)")
    }
  }

  private func handleMonoCollectionInvalidation(_ notification: Notification) {
    guard let characterId = MonoCollectionInvalidation.characterId(from: notification),
      loadedCharacterIds.contains(characterId)
    else {
      return
    }
    Task {
      await loadCollectionStatuses(characterIds: [characterId])
    }
  }

  func load(limit: Int, offset: Int) async -> PagedDTO<CharacterRelationDTO>? {
    do {
      let resp = try await CharacterService.getCharacterRelations(
        characterId, limit: limit, offset: offset)
      let characterIds = resp.data.map { $0.character.id }
      loadedCharacterIds.formUnion(characterIds)
      await loadCollectionStatuses(characterIds: characterIds)
      return resp
    } catch {
      Notifier.shared.alert(error: error)
    }
    return nil
  }

  var body: some View {
    ScrollView {
      OffsetPagedView<CharacterRelationDTO, _>(reloader: reloader, nextPageFunc: load) { item in
        GlassCharacterRelationCard(
          item: item,
          isCollected: collectionStatuses[item.character.id] ?? false
        )
      }
      .padding(.horizontal, theme.metrics.screenPadding)
      .padding(.vertical, 12)
    }
    .onReceive(
      NotificationCenter.default.publisher(for: MonoCollectionInvalidation.notificationName),
      perform: handleMonoCollectionInvalidation
    )
    .onAppear {
      Task {
        await loadCollectionStatuses(characterIds: Array(loadedCharacterIds))
      }
    }
  }
}

struct GlassCharacterIndexListView: View {
  let characterId: Int

  @Environment(\.theme) private var theme
  @State private var reloader = false

  func load(limit: Int, offset: Int) async -> PagedDTO<SlimIndexDTO>? {
    do {
      let resp = try await CharacterService.getCharacterIndexes(
        characterId: characterId, limit: limit, offset: offset)
      return resp
    } catch {
      Notifier.shared.alert(error: error)
    }
    return nil
  }

  var body: some View {
    ScrollView {
      OffsetPagedView<SlimIndexDTO, _>(reloader: reloader, nextPageFunc: load) { item in
        GlassIndexCard(index: item)
      }
      .padding(.horizontal, theme.metrics.screenPadding)
      .padding(.vertical, 12)
    }
  }
}
