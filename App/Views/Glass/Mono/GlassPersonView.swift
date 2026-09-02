import Flow
import OSLog
import SwiftUI

struct GlassPersonDetailView: View {
  let person: PersonDTO
  let detail: PersonDetailDTO
  let reload: () async -> Void

  @AppStorage("isolationMode") private var isolationMode = false

  @Environment(\.theme) private var theme
  @State private var updating: Bool = false

  private var collected: Bool {
    (person.collectedAt ?? 0) != 0
  }

  private var subname: String {
    person.nameCN.isEmpty ? person.name : person.nameCN
  }

  private var careers: [PersonCareer] {
    Set(person.career).sorted { $0.rawValue < $1.rawValue }
  }

  func collect() async {
    updating = true
    defer { updating = false }
    do {
      if person.collectedAt ?? 0 == 0 {
        try await PersonRepository.collectPerson(person.id)
      } else {
        try await PersonRepository.uncollectPerson(person.id)
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
        Text(person.name)
          .font(.title3.weight(.bold))
          .foregroundStyle(theme.title)
          .textSelection(.enabled)
        HStack(alignment: .top, spacing: 12) {
          ImageView(img: person.images?.resize(.r400))
            .imageStyle(width: 104, height: 146, alignment: .top)
            .imageType(.person)
            .imageNSFW(person.nsfw)
            .enableImagePreview(
              person.images?.large,
              zoomID: ZoomNavigationID(type: .person, id: person.id)
            )
          VStack(alignment: .leading, spacing: 7) {
            HStack(spacing: 6) {
              GlassMonoTag(text: person.type.description, tone: .accent)
              if person.lock {
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
            if !careers.isEmpty {
              HFlow(spacing: 5) {
                ForEach(careers, id: \.self) { career in
                  GlassMonoTag(text: career.description)
                }
              }
            }
            NavigationLink(value: NavDestination.infobox("人物信息", person.infobox)) {
              HStack(alignment: .top, spacing: 4) {
                Text(person.info)
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
              GlassMonoCaption(text: "\(person.collects) 人收藏")
              Spacer(minLength: 0)
              if !isolationMode {
                CommentListNavigationLink(
                  route: CommentListRoute(parent: .person(person.id)),
                  count: person.comment
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
        GlassInfoboxCard(title: "人物信息", infobox: person.infobox)
        GlassSummaryCard(summary: person.summary)
        GlassMonoSection(
          title: "最近出演角色", systemImage: "theatermasks",
          destination: detail.casts.isEmpty ? nil : NavDestination.personCastList(person.id),
          moreTitle: "更多角色 »", isEmpty: detail.casts.isEmpty,
          emptyTitle: "暂无出演角色", emptyDescription: "还没有关联的出演角色"
        ) {
          VStack(spacing: theme.metrics.listSpacing) {
            ForEach(detail.casts) { item in
              GlassPersonCastCard(item: item)
            }
          }
        }
        GlassMonoSection(
          title: "最近参与", systemImage: "film.stack",
          destination: detail.works.isEmpty ? nil : NavDestination.personWorkList(person.id),
          moreTitle: "更多作品 »", isEmpty: detail.works.isEmpty,
          emptyTitle: "暂无参与作品", emptyDescription: "还没有关联的参与作品"
        ) {
          VStack(spacing: theme.metrics.listSpacing) {
            ForEach(detail.works) { item in
              GlassPersonWorkCard(item: item)
            }
          }
        }
        GlassPersonRelationsSection(personId: person.id, relations: detail.relations)
        GlassMonoSection(
          title: "相关目录", systemImage: "list.bullet.rectangle.portrait",
          destination: detail.indexes.isEmpty ? nil : NavDestination.personIndexList(person.id),
          moreTitle: "更多目录 »", isEmpty: detail.indexes.isEmpty,
          emptyTitle: "暂无相关目录", emptyDescription: "还没有目录收录该人物"
        ) {
          GlassIndexRowsCard(indexes: detail.indexes)
        }
      }
      .padding(.horizontal, theme.metrics.screenPadding)
      .padding(.vertical, 12)
    }
  }
}

struct GlassPersonCastCard: View {
  let item: PersonCastDTO

  @AppStorage("titlePreference") var titlePreference: TitlePreference = .original

  @Environment(\.theme) private var theme

  var body: some View {
    CardView(padding: theme.metrics.cardPadding) {
      VStack(alignment: .leading, spacing: 10) {
        HStack(spacing: 10) {
          ImageView(img: item.character.images?.resize(.r200))
            .imageStyle(width: 46, height: 46, alignment: .top)
            .imageType(.person)
            .imageNSFW(item.character.nsfw)
            .imageNavLink(item.character.link)
          VStack(alignment: .leading, spacing: 4) {
            Text(
              item.character.title(with: titlePreference)
                .withLink(item.character.link, linkColor: theme.link)
            )
            .font(.footnote.weight(.bold))
            .lineLimit(2)
            if let info = item.character.info, !info.isEmpty {
              Text(info)
                .font(.caption2)
                .foregroundStyle(theme.tertiaryText)
                .lineLimit(1)
            }
          }
          Spacer(minLength: 0)
        }
        if !item.relations.isEmpty {
          ThemedDivider()
          VStack(spacing: 8) {
            ForEach(item.relations) { relation in
              HStack(spacing: 8) {
                ImageView(img: relation.subject.images?.resize(.r200))
                  .imageStyle(width: 32, height: 44)
                  .imageType(.subject)
                  .imageNSFW(relation.subject.nsfw)
                  .imageNavLink(relation.subject.link)
                VStack(alignment: .leading, spacing: 4) {
                  Text(
                    relation.subject.title(with: titlePreference)
                      .withLink(relation.subject.link, linkColor: theme.link)
                  )
                  .font(.caption.weight(.semibold))
                  .lineLimit(1)
                  HStack(spacing: 6) {
                    GlassTypeBadge(type: relation.subject.type)
                    GlassMonoTag(text: relation.type.description, tone: .accent)
                    Spacer(minLength: 0)
                  }
                }
                Spacer(minLength: 0)
              }
            }
          }
        }
      }
      .frame(maxWidth: .infinity, alignment: .leading)
    }
  }
}

struct GlassPersonWorkCard: View {
  let item: PersonWorkDTO

  @AppStorage("titlePreference") var titlePreference: TitlePreference = .original

  @Environment(\.theme) private var theme

  var body: some View {
    CardView(padding: theme.metrics.cardPadding) {
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
            Spacer(minLength: 0)
          }
          if let info = item.subject.info, !info.isEmpty {
            Text(info)
              .font(.caption2)
              .foregroundStyle(theme.tertiaryText)
              .lineLimit(1)
          }
          if !item.positions.isEmpty {
            HFlow(spacing: 5) {
              ForEach(item.positions) { position in
                GlassMonoTag(text: position.type.cn, tone: .accent)
              }
            }
          }
        }
        Spacer(minLength: 0)
      }
      .frame(maxWidth: .infinity, alignment: .leading)
    }
  }
}

struct GlassPersonRelationsSection: View {
  let personId: Int
  let relations: [PersonRelationDTO]

  @Environment(\.theme) private var theme
  @State private var collectionStatuses: [Int: Bool] = [:]

  private var collectionPersonIds: [Int] {
    relations.map { $0.person.id }
  }

  private func loadCollections() async {
    do {
      let db = try await AppContext.shared.getDB()
      collectionStatuses = try await db.personCollectionStatuses(personIds: collectionPersonIds)
    } catch {
      Logger.app.error("Failed to load person collection statuses: \(error)")
    }
  }

  private func handleMonoCollectionInvalidation(_ notification: Notification) {
    guard let personId = MonoCollectionInvalidation.personId(from: notification),
      collectionPersonIds.contains(personId)
    else {
      return
    }
    Task {
      await loadCollections()
    }
  }

  var body: some View {
    GlassMonoSection(
      title: "关联人物", systemImage: "person.2",
      destination: relations.isEmpty ? nil : NavDestination.personRelationList(personId),
      moreTitle: "更多人物 »", isEmpty: relations.isEmpty,
      emptyTitle: "暂无关联人物", emptyDescription: "还没有关联的其他人物"
    ) {
      ScrollView(.horizontal, showsIndicators: false) {
        LazyHStack(alignment: .top, spacing: 9) {
          ForEach(relations) { item in
            GlassPersonRelationTile(
              item: item,
              isCollected: collectionStatuses[item.person.id] ?? false
            )
          }
        }
        .padding(.horizontal, 2)
        .padding(.vertical, 4)
      }
      .scrollClipDisabled()
    }
    .task(id: collectionPersonIds) {
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

struct GlassPersonRelationTile: View {
  let item: PersonRelationDTO
  let isCollected: Bool

  @AppStorage("titlePreference") var titlePreference: TitlePreference = .original

  private var relationText: String {
    item.relation.cn.isEmpty ? "关联" : item.relation.cn
  }

  var body: some View {
    SpoilerRevealContainer(isSpoiler: item.spoiler) {
      GlassMonoPortraitTile(
        image: item.person.images?.resize(.r200),
        nsfw: item.person.nsfw,
        isCollected: isCollected,
        link: item.person.link,
        caption: relationText,
        title: item.person.title(with: titlePreference),
        footnote: item.ended ? "已结束" : nil
      )
    }
  }
}

struct GlassPersonRelationCard: View {
  let item: PersonRelationDTO
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
          ImageView(img: item.person.images?.resize(.r200))
            .imageStyle(width: 56, height: 56, alignment: .top)
            .imageType(.person)
            .imageNSFW(item.person.nsfw)
            .imageCollectedStatus(isCollected)
            .imageNavLink(item.person.link)
          VStack(alignment: .leading, spacing: 5) {
            Text(
              item.person.title(with: titlePreference)
                .withLink(item.person.link, linkColor: theme.link)
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

struct GlassPersonCastListView: View {
  let personId: Int

  @Environment(\.theme) private var theme
  @State private var type: CastType = .none
  @State private var reloader = false

  func load(limit: Int, offset: Int) async -> PagedDTO<PersonCastDTO>? {
    do {
      let resp = try await PersonService.getPersonCasts(
        personId, type: type.rawValue, limit: limit, offset: offset)
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
        OffsetPagedView<PersonCastDTO, _>(reloader: reloader, nextPageFunc: load) { item in
          GlassPersonCastCard(item: item)
        }
        .padding(.horizontal, theme.metrics.screenPadding)
        .padding(.bottom, 12)
      }
    }
  }
}

struct GlassPersonWorkListView: View {
  let personId: Int

  @Environment(\.theme) private var theme
  @State private var subjectType: SubjectType = .none
  @State private var reloader = false

  func load(limit: Int, offset: Int) async -> PagedDTO<PersonWorkDTO>? {
    do {
      let resp = try await PersonService.getPersonWorks(
        personId, subjectType: subjectType, limit: limit, offset: offset)
      return resp
    } catch {
      Notifier.shared.alert(error: error)
    }
    return nil
  }

  var body: some View {
    VStack(spacing: 0) {
      ScrollView(.horizontal, showsIndicators: false) {
        HStack(spacing: 8) {
          ForEach(SubjectType.allCases) { type in
            GlassChip(title: type.description, isSelected: subjectType == type) {
              subjectType = type
              withAnimation(.default) {
                reloader.toggle()
              }
            }
          }
        }
        .padding(.horizontal, 2)
        .padding(.vertical, 3)
      }
      .scrollClipDisabled()
      .padding(.horizontal, theme.metrics.screenPadding)
      .padding(.vertical, 6)
      ScrollView {
        OffsetPagedView<PersonWorkDTO, _>(
          limit: 10, reloader: reloader, nextPageFunc: load
        ) { item in
          GlassPersonWorkCard(item: item)
        }
        .padding(.horizontal, theme.metrics.screenPadding)
        .padding(.bottom, 12)
      }
    }
  }
}

struct GlassPersonRelationListView: View {
  let personId: Int

  @Environment(\.theme) private var theme
  @State private var reloader = false
  @State private var collectionStatuses: [Int: Bool] = [:]
  @State private var loadedPersonIds: Set<Int> = []

  private func loadCollectionStatuses(personIds: [Int]) async {
    guard !personIds.isEmpty else { return }
    do {
      guard let db = await AppContext.shared.databaseIfAvailable() else { return }
      let statuses = try await db.personCollectionStatuses(personIds: personIds)
      collectionStatuses.merge(statuses) { _, new in new }
    } catch {
      Logger.app.error("Failed to load person collection statuses: \(error)")
    }
  }

  private func handleMonoCollectionInvalidation(_ notification: Notification) {
    guard let personId = MonoCollectionInvalidation.personId(from: notification),
      loadedPersonIds.contains(personId)
    else {
      return
    }
    Task {
      await loadCollectionStatuses(personIds: [personId])
    }
  }

  func load(limit: Int, offset: Int) async -> PagedDTO<PersonRelationDTO>? {
    do {
      let resp = try await PersonService.getPersonRelations(
        personId, limit: limit, offset: offset)
      let personIds = resp.data.map { $0.person.id }
      loadedPersonIds.formUnion(personIds)
      await loadCollectionStatuses(personIds: personIds)
      return resp
    } catch {
      Notifier.shared.alert(error: error)
    }
    return nil
  }

  var body: some View {
    ScrollView {
      OffsetPagedView<PersonRelationDTO, _>(reloader: reloader, nextPageFunc: load) { item in
        GlassPersonRelationCard(
          item: item,
          isCollected: collectionStatuses[item.person.id] ?? false
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
        await loadCollectionStatuses(personIds: Array(loadedPersonIds))
      }
    }
  }
}

struct GlassPersonIndexListView: View {
  let personId: Int

  @Environment(\.theme) private var theme
  @State private var reloader = false

  func load(limit: Int, offset: Int) async -> PagedDTO<SlimIndexDTO>? {
    do {
      let resp = try await PersonService.getPersonIndexes(
        personId: personId, limit: limit, offset: offset)
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
