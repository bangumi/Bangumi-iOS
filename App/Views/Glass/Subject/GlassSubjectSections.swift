import Flow
import OSLog
import SwiftUI

struct GlassSubjectEmptyRow: View {
  let text: String

  @Environment(\.theme) private var theme

  private var shape: RoundedRectangle {
    RoundedRectangle(cornerRadius: theme.metrics.embedRadius, style: .continuous)
  }

  var body: some View {
    HStack {
      Spacer(minLength: 0)
      Text(text)
        .font(.caption)
        .foregroundStyle(theme.tertiaryText)
      Spacer(minLength: 0)
    }
    .padding(.vertical, 14)
    .background(theme.embedFill, in: shape)
    .overlay {
      shape.strokeBorder(theme.embedBorder, lineWidth: 1)
    }
  }
}

struct GlassSubjectSummary: View {
  let subject: SubjectDTO

  @Environment(\.theme) private var theme

  private var metaTags: [Tag] {
    var result: [Tag] = []
    for name in subject.metaTags {
      if let tag = subject.tags.first(where: { $0.name == name }) {
        result.append(tag)
      } else {
        result.append(Tag(name: name, count: 0))
      }
    }
    return result
  }

  private var tags: [Tag] {
    let count = max(20 - metaTags.count, 0)
    let result = subject.tags.sorted { $0.count > $1.count }.filter { !metaTags.contains($0) }
      .prefix(count)
    return Array(result)
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 10) {
      ThemedSectionHeader("简介")
      CardView(padding: theme.metrics.cardPadding) {
        VStack(alignment: .leading, spacing: 12) {
          if subject.summary.isEmpty {
            Text("暂无简介")
              .font(.caption)
              .foregroundStyle(theme.tertiaryText)
              .frame(maxWidth: .infinity, alignment: .leading)
          } else {
            BBCodeView(subject.summary, textSize: 14)
              .textSelection(.enabled)
              .tint(theme.link)
              .frame(maxWidth: .infinity, alignment: .leading)
          }
          if !metaTags.isEmpty || !tags.isEmpty {
            ThemedDivider()
            HFlow(alignment: .center, spacing: 6) {
              ForEach(metaTags, id: \.name) { tag in
                tagChip(tag, tagsCat: .meta)
              }
              ForEach(tags, id: \.name) { tag in
                tagChip(tag, tagsCat: .subject)
              }
            }
          }
        }
      }
    }
  }

  private func tagChip(_ tag: Tag, tagsCat: SubjectTagsCategory) -> some View {
    let isMeta = tagsCat == .meta
    let shape = RoundedRectangle(cornerRadius: theme.metrics.cellRadius, style: .continuous)
    return NavigationLink(
      value: NavDestination.subjectTagBrowsing(subject.type, tag.name, tagsCat)
    ) {
      HStack(spacing: 4) {
        Text(tag.name)
          .font(.caption)
          .fontWeight(isMeta ? .bold : .regular)
          .foregroundStyle(isMeta ? theme.onTintText : theme.secondaryText)
          .lineLimit(1)
        Text("\(tag.count)")
          .font(.caption2.weight(.semibold))
          .monospaced()
          .foregroundStyle(isMeta ? theme.onTintText.opacity(0.7) : theme.tertiaryText)
      }
      .padding(.horizontal, 10)
      .padding(.vertical, 4)
      .background(isMeta ? theme.tint : theme.controlFill, in: shape)
      .overlay {
        if !isMeta {
          shape.strokeBorder(theme.controlBorder, lineWidth: 1)
        }
      }
    }
    .buttonStyle(.plain)
  }
}

struct GlassSubjectCharacters: View {
  let subjectId: Int
  let characters: [SubjectCharacterDTO]

  @AppStorage("isolationMode") var isolationMode: Bool = false

  @State private var collectionStatuses: [Int: Bool] = [:]

  private var collectionCharacterIds: [Int] {
    characters.map { $0.character.id }
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
    VStack(alignment: .leading, spacing: 10) {
      ThemedSectionHeader("角色介绍") {
        if characters.count > 0 {
          NavigationLink(value: NavDestination.subjectCharacterList(subjectId)) {
            GlassMoreLabel(title: "更多角色 »")
          }
          .buttonStyle(.plain)
        }
      }

      if characters.isEmpty {
        GlassSubjectEmptyRow(text: "暂无角色")
      } else {
        ScrollView(.horizontal, showsIndicators: false) {
          HStack(alignment: .top, spacing: 9) {
            ForEach(characters, id: \.character.id) { item in
              GlassCharacterCard(
                item: item,
                isolationMode: isolationMode,
                isCollected: collectionStatuses[item.character.id] ?? false
              )
            }
          }
          .padding(.vertical, 2)
        }
        .scrollClipDisabled()
      }
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

struct GlassCharacterCard: View {
  let item: SubjectCharacterDTO
  let isolationMode: Bool
  let isCollected: Bool

  @AppStorage("titlePreference") var titlePreference: TitlePreference = .original

  @Environment(\.theme) private var theme

  var body: some View {
    NavigationLink(value: NavDestination.character(item.character.id, zoom: true)) {
      CardView(padding: 11) {
        ZStack(alignment: .topTrailing) {
          VStack(spacing: 6) {
            ImageView(img: item.character.images?.medium)
              .imageStyle(width: 52, height: 52, cornerRadius: 26, alignment: .top)
              .imageType(.avatar)
              .imageNSFW(item.character.nsfw)

            Text(item.character.title(with: titlePreference))
              .font(.caption.weight(.bold))
              .foregroundStyle(theme.cardTitle)
              .lineLimit(1)

            HStack(spacing: 3) {
              Text(item.type.description)
                .font(.caption2.weight(.bold))
                .monospaced()
                .foregroundStyle(item.type == .main ? theme.onTintText : theme.secondaryText)
              if let comment = item.character.comment, comment > 0, !isolationMode {
                Text("(+\(comment))")
                  .font(.caption2)
                  .monospacedDigit()
                  .foregroundStyle(theme.accent)
                  .lineLimit(1)
              }
            }

            if let cast = item.casts.first {
              Text("\(cast.relation.description) \(cast.person.title(with: titlePreference))")
                .font(.caption2)
                .foregroundStyle(theme.tertiaryText)
                .lineLimit(1)
            }
          }
          .frame(maxWidth: .infinity)

          if isCollected {
            Image(systemName: "heart.fill")
              .font(.caption2)
              .foregroundStyle(theme.accent)
          }
        }
      }
    }
    .buttonStyle(.plain)
    .zoomSource(ZoomNavigationID(type: .character, id: item.character.id))
    .frame(width: 96)
  }
}

struct GlassSubjectRelations: View {
  let subjectId: Int
  let relations: [SubjectRelationDTO]

  @AppStorage("titlePreference") var titlePreference: TitlePreference = .original

  @Environment(\.theme) private var theme
  @State private var collections: [Int: CollectionType] = [:]
  @State private var activeSubject: SlimSubjectDTO? = nil

  private var collectionSubjectIds: [Int] {
    relations.map { $0.subject.id }
  }

  private func loadCollections() async {
    do {
      let db = try await AppContext.shared.getDB()
      collections = try await db.getCollectionTypes(subjectIds: collectionSubjectIds)
    } catch {
      Logger.app.error("Failed to load collections: \(error)")
    }
  }

  private func relationLabel(_ relation: SubjectRelationDTO) -> String {
    if relation.relation.id > 1, !relation.relation.cn.isEmpty {
      return relation.relation.cn
    }
    return relation.subject.type.description
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 10) {
      ThemedSectionHeader("关联条目") {
        if relations.count > 0 {
          NavigationLink(value: NavDestination.subjectRelationList(subjectId)) {
            GlassMoreLabel(title: "更多条目 »")
          }
          .buttonStyle(.plain)
        }
      }

      if relations.isEmpty {
        GlassSubjectEmptyRow(text: "暂无关联条目")
      } else {
        ScrollView(.horizontal, showsIndicators: false) {
          LazyHStack(alignment: .top, spacing: 9) {
            ForEach(relations) { relation in
              VStack(alignment: .leading, spacing: 5) {
                Text(relationLabel(relation))
                  .font(.caption2.weight(.bold))
                  .monospaced()
                  .foregroundStyle(theme.placeholder)
                  .lineLimit(1)
                ImageView(img: relation.subject.images?.resize(.r200))
                  .imageCollectionStatus(ctype: collections[relation.subject.id])
                  .imageStyle(width: 88, height: 122, cornerRadius: theme.metrics.coverRadius)
                  .imageType(.subject)
                  .imageNSFW(relation.subject.nsfw)
                  .imageNavLink(relation.subject.link)
                  .contextMenu {
                    Button {
                      activeSubject = relation.subject
                    } label: {
                      Label("管理收藏", systemImage: "square.and.pencil")
                    }
                  } preview: {
                    SubjectCardView(subject: relation.subject)
                      .padding()
                      .frame(idealWidth: 360)
                  }
                  .shadow(
                    color: theme.cardShadow.color, radius: theme.cardShadow.radius,
                    y: theme.cardShadow.y)
                Text(relation.subject.title(with: titlePreference))
                  .font(.caption)
                  .foregroundStyle(theme.body)
                  .multilineTextAlignment(.leading)
                  .truncationMode(.middle)
                  .lineLimit(2)
              }
              .frame(width: 88, alignment: .leading)
            }
          }
          .padding(.horizontal, 2)
          .padding(.vertical, 2)
        }
        .scrollClipDisabled()
      }
    }
    .task(id: collectionSubjectIds) {
      await loadCollections()
    }
    .onChange(of: activeSubject) { _, newValue in
      if newValue == nil {
        Task {
          await loadCollections()
        }
      }
    }
    .sheet(item: $activeSubject) { item in
      SubjectCollectionBoxView(subjectId: item.id)
    }
  }
}

struct GlassSubjectRecs: View {
  let subjectId: Int
  let recs: [SubjectRecDTO]

  @AppStorage("titlePreference") var titlePreference: TitlePreference = .original

  @Environment(\.theme) private var theme
  @State private var collections: [Int: CollectionType] = [:]
  @State private var activeSubject: SlimSubjectDTO? = nil

  private var collectionSubjectIds: [Int] {
    recs.map { $0.subject.id }
  }

  private func loadCollections() async {
    do {
      let db = try await AppContext.shared.getDB()
      collections = try await db.getCollectionTypes(subjectIds: collectionSubjectIds)
    } catch {
      Logger.app.error("Failed to load collections: \(error)")
    }
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 10) {
      ThemedSectionHeader("猜你喜欢")

      if recs.isEmpty {
        GlassSubjectEmptyRow(text: "暂无推荐")
      } else {
        ScrollView(.horizontal, showsIndicators: false) {
          LazyHStack(alignment: .top, spacing: 9) {
            ForEach(recs) { rec in
              VStack(alignment: .leading, spacing: 6) {
                ImageView(img: rec.subject.images?.resize(.r200))
                  .imageCollectionStatus(ctype: collections[rec.subject.id])
                  .imageStyle(width: 88, height: 122, cornerRadius: theme.metrics.coverRadius)
                  .imageType(.subject)
                  .imageNSFW(rec.subject.nsfw)
                  .imageNavLink(rec.subject.link)
                  .contextMenu {
                    Button {
                      activeSubject = rec.subject
                    } label: {
                      Label("管理收藏", systemImage: "square.and.pencil")
                    }
                  } preview: {
                    SubjectCardView(subject: rec.subject)
                      .padding()
                      .frame(idealWidth: 360)
                  }
                  .shadow(
                    color: theme.cardShadow.color, radius: theme.cardShadow.radius,
                    y: theme.cardShadow.y)
                Text(rec.subject.title(with: titlePreference))
                  .font(.caption)
                  .foregroundStyle(theme.body)
                  .multilineTextAlignment(.leading)
                  .truncationMode(.middle)
                  .lineLimit(2)
              }
              .frame(width: 88, alignment: .leading)
            }
          }
          .padding(.horizontal, 2)
          .padding(.vertical, 2)
        }
        .scrollClipDisabled()
      }
    }
    .task(id: collectionSubjectIds) {
      await loadCollections()
    }
    .onChange(of: activeSubject) { _, newValue in
      if newValue == nil {
        Task {
          await loadCollections()
        }
      }
    }
    .sheet(item: $activeSubject) { item in
      SubjectCollectionBoxView(subjectId: item.id)
    }
  }
}

struct GlassSubjectIndexes: View {
  let subjectId: Int
  let indexes: [SlimIndexDTO]

  @Environment(\.theme) private var theme

  var body: some View {
    VStack(alignment: .leading, spacing: 10) {
      ThemedSectionHeader("相关目录") {
        if indexes.count > 0 {
          NavigationLink(value: NavDestination.subjectIndexList(subjectId)) {
            GlassMoreLabel(title: "更多目录 »")
          }
          .buttonStyle(.plain)
        }
      }

      if indexes.isEmpty {
        GlassSubjectEmptyRow(text: "暂无相关目录")
      } else {
        CardView(padding: theme.metrics.cardPadding) {
          VStack(spacing: 0) {
            ForEach(indexes) { index in
              GlassSubjectIndexRow(index: index)
              if index.id != indexes.last?.id {
                ThemedDivider()
              }
            }
          }
        }
      }
    }
  }
}

struct GlassSubjectIndexRow: View {
  let index: SlimIndexDTO

  @Environment(\.theme) private var theme

  var body: some View {
    NavigationLink(value: NavDestination.index(index.id)) {
      HStack(spacing: 10) {
        Image(systemName: "list.bullet.rectangle")
          .font(.footnote)
          .foregroundStyle(theme.onTintText)
          .frame(width: 34, height: 34)
          .background(
            theme.tint,
            in: RoundedRectangle(cornerRadius: theme.metrics.cellRadius, style: .continuous)
          )
        VStack(alignment: .leading, spacing: 3) {
          Text(index.title)
            .font(.footnote.weight(.bold))
            .foregroundStyle(theme.cardTitle)
            .multilineTextAlignment(.leading)
            .lineLimit(1)
          HStack(spacing: 4) {
            if let user = index.user {
              Text(user.nickname).lineLimit(1)
              Text(verbatim: "·")
            } else if index.private {
              Label("私有", systemImage: "lock")
              Text(verbatim: "·")
            }
            Text("收录 \(index.total) 个条目").monospacedDigit()
          }
          .font(.caption2)
          .foregroundStyle(theme.placeholder)
          statsRow
          HStack(spacing: 4) {
            Text("创建 \(index.createdAt.dateDisplay)")
            Text(verbatim: "·")
            Text("更新 \(index.updatedAt.dateDisplay)")
          }
          .font(.caption2)
          .monospacedDigit()
          .foregroundStyle(theme.tertiaryText)
        }
        Spacer(minLength: 0)
        Image(systemName: "chevron.right")
          .font(.caption)
          .foregroundStyle(theme.disabled)
      }
      .padding(.vertical, 10)
    }
    .buttonStyle(.plain)
  }

  private var statsRow: some View {
    HStack(spacing: 6) {
      if let count = index.stats.subject.book, count > 0 {
        Label("\(count)", systemImage: SubjectType.book.icon)
      }
      if let count = index.stats.subject.anime, count > 0 {
        Label("\(count)", systemImage: SubjectType.anime.icon)
      }
      if let count = index.stats.subject.music, count > 0 {
        Label("\(count)", systemImage: SubjectType.music.icon)
      }
      if let count = index.stats.subject.game, count > 0 {
        Label("\(count)", systemImage: SubjectType.game.icon)
      }
      if let count = index.stats.subject.real, count > 0 {
        Label("\(count)", systemImage: SubjectType.real.icon)
      }
      if let count = index.stats.character, count > 0 {
        Label("\(count)", systemImage: IndexRelatedCategory.character.icon)
      }
      if let count = index.stats.person, count > 0 {
        Label("\(count)", systemImage: IndexRelatedCategory.person.icon)
      }
      if let count = index.stats.episode, count > 0 {
        Label("\(count)", systemImage: IndexRelatedCategory.episode.icon)
      }
      if let count = index.stats.blog, count > 0 {
        Label("\(count)", systemImage: IndexRelatedCategory.blog.icon)
      }
      if let count = index.stats.groupTopic, count > 0 {
        Label("\(count)", systemImage: IndexRelatedCategory.groupTopic.icon)
      }
      if let count = index.stats.subjectTopic, count > 0 {
        Label("\(count)", systemImage: IndexRelatedCategory.subjectTopic.icon)
      }
    }
    .labelStyle(.compact)
    .font(.caption2)
    .monospacedDigit()
    .foregroundStyle(theme.tertiaryText)
  }
}

struct GlassSubjectFilterTabs: View {
  @Binding var selection: FilterMode
  let disabled: Bool

  @Environment(\.theme) private var theme

  private func label(_ mode: FilterMode) -> String {
    switch mode {
    case .all:
      return "所有人"
    case .friends:
      return "好友"
    }
  }

  var body: some View {
    HStack(spacing: 2) {
      ForEach(FilterMode.allCases, id: \.self) { mode in
        Button {
          guard selection != mode else { return }
          withAnimation(.default) {
            selection = mode
          }
        } label: {
          Text(label(mode))
            .font(.caption2.weight(selection == mode ? .bold : .semibold))
            .foregroundStyle(selection == mode ? theme.onTintText : theme.tertiaryText)
            .padding(.horizontal, 9)
            .padding(.vertical, 3)
            .background {
              if selection == mode {
                RoundedRectangle(cornerRadius: theme.metrics.badgeRadius, style: .continuous)
                  .fill(theme.cardFillStrong)
                  .overlay {
                    RoundedRectangle(
                      cornerRadius: theme.metrics.badgeRadius, style: .continuous
                    )
                    .strokeBorder(theme.accent.opacity(0.35), lineWidth: 1)
                  }
              }
            }
        }
        .buttonStyle(.plain)
      }
    }
    .padding(2)
    .background(
      theme.track,
      in: RoundedRectangle(cornerRadius: theme.metrics.cellRadius, style: .continuous)
    )
    .disabled(disabled)
  }
}

struct GlassSubjectCollects: View {
  @AppStorage("isAuthenticated") var isAuthenticated: Bool = false
  @AppStorage("subjectCollectsFilterMode") var subjectCollectsFilterMode: FilterMode = .all

  let subject: SubjectDTO
  let latestCollects: [SubjectCollectDTO]

  @Environment(\.theme) private var theme
  @State private var isLoading: Bool = false
  @State private var collects: [SubjectCollectDTO]

  init(subject: SubjectDTO, collects: [SubjectCollectDTO]) {
    self.subject = subject
    self.latestCollects = collects
    _collects = State(initialValue: collects)
  }

  private var title: String {
    switch subject.type {
    case .book:
      return "谁读这本书?"
    case .anime:
      return "谁看这部动画?"
    case .music:
      return "谁听这张唱片?"
    case .game:
      return "谁玩这部游戏?"
    case .real:
      return "谁看这部影视?"
    default:
      return "谁收藏这个条目?"
    }
  }

  private var moreText: String {
    switch subjectCollectsFilterMode {
    case .all:
      return "更多用户 »"
    case .friends:
      return "更多好友 »"
    }
  }

  private var emptyText: String {
    switch subjectCollectsFilterMode {
    case .all:
      return "暂无用户收藏"
    case .friends:
      return "暂无好友收藏"
    }
  }

  private func updateCollects() {
    guard !isLoading else { return }
    withAnimation(.default) {
      isLoading = true
    }

    Task {
      do {
        let resp = try await SubjectService.getSubjectCollects(
          subject.id,
          mode: subjectCollectsFilterMode,
          limit: 10
        )
        withAnimation(.default) {
          collects = resp.data
          isLoading = false
        }
      } catch {
        Notifier.shared.alert(error: error)
        withAnimation(.default) {
          isLoading = false
        }
      }
    }
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 10) {
      ThemedSectionHeader(title) {
        HStack(spacing: 8) {
          if isAuthenticated {
            GlassSubjectFilterTabs(
              selection: $subjectCollectsFilterMode, disabled: isLoading)
          }
          if collects.count > 0 {
            NavigationLink(value: NavDestination.subjectCollectsList(subject.id)) {
              GlassMoreLabel(title: moreText)
            }
            .buttonStyle(.plain)
          }
        }
      }

      if collects.isEmpty {
        GlassSubjectEmptyRow(text: emptyText)
      } else {
        ScrollView(.horizontal, showsIndicators: false) {
          LazyHStack(alignment: .top, spacing: 12) {
            ForEach(collects.prefix(10)) { collect in
              VStack(spacing: 5) {
                ImageView(img: collect.user.avatar?.large)
                  .imageCollectionStatus(ctype: collect.interest.type)
                  .imageStyle(width: 46, height: 46, cornerRadius: 23)
                  .imageType(.avatar)
                  .contextMenu {
                    NavigationLink(value: NavDestination.user(collect.user.username)) {
                      Label("查看用户主页", systemImage: "person.circle")
                    }
                  } preview: {
                    SubjectCollectRowView(collect: collect, subjectType: subject.type)
                      .padding()
                      .frame(idealWidth: 360)
                  }
                Text(collect.user.nickname)
                  .font(.caption2)
                  .foregroundStyle(theme.secondaryText)
                  .lineLimit(1)
                StarsView(score: Float(collect.interest.rate), size: 8)
              }
              .frame(width: 56)
            }
          }
          .padding(.horizontal, 2)
          .padding(.vertical, 2)
        }
        .scrollClipDisabled()
      }
    }
    .onChange(of: latestCollects) { _, newValue in
      guard !isLoading else { return }
      withAnimation(.default) {
        collects = newValue
      }
    }
    .onChange(of: subjectCollectsFilterMode) { _, _ in
      updateCollects()
    }
  }
}

struct GlassSubjectReviews: View {
  let subjectId: Int
  let reviews: [SubjectReviewDTO]

  @AppStorage("hideBlocklist") var hideBlocklist: Bool = false
  @AppStorage("blocklist") var blocklist: [Int] = []

  @Environment(\.theme) private var theme

  var body: some View {
    VStack(alignment: .leading, spacing: 10) {
      ThemedSectionHeader("评论") {
        if reviews.count > 0 {
          NavigationLink(value: NavDestination.subjectReviewList(subjectId)) {
            GlassMoreLabel(title: "更多评论 »")
          }
          .buttonStyle(.plain)
        }
      }

      if reviews.isEmpty {
        GlassSubjectEmptyRow(text: "暂无评论")
      } else {
        VStack(spacing: theme.metrics.listSpacing) {
          ForEach(reviews) { review in
            if !hideBlocklist || !blocklist.contains(review.user.id) {
              GlassSubjectReviewCard(item: review)
            }
          }
        }
      }
    }
  }
}

struct GlassSubjectReviewCard: View {
  let item: SubjectReviewDTO

  @Environment(\.theme) private var theme

  var body: some View {
    NavigationLink(value: NavDestination.blog(item.entry.id)) {
      CardView(padding: theme.metrics.cardPadding) {
        VStack(alignment: .leading, spacing: 9) {
          HStack(spacing: 9) {
            ImageView(img: item.user.avatar?.large)
              .imageStyle(width: 34, height: 34, cornerRadius: 17)
              .imageType(.avatar)
            VStack(alignment: .leading, spacing: 1) {
              Text(item.user.nickname)
                .font(.footnote.weight(.bold))
                .foregroundStyle(theme.cardTitle)
                .lineLimit(1)
              HStack(spacing: 4) {
                Text(item.entry.createdAt.datetimeDisplay).lineLimit(1)
                if item.entry.replies > 0 {
                  Text(verbatim: "·")
                  Text("\(item.entry.replies) 回复")
                }
              }
              .font(.caption2)
              .monospacedDigit()
              .foregroundStyle(theme.placeholder)
            }
            Spacer(minLength: 0)
          }
          Text(item.entry.title)
            .font(.footnote.weight(.heavy))
            .foregroundStyle(theme.title)
            .multilineTextAlignment(.leading)
            .lineLimit(2)
          Text("\(item.entry.summary)...")
            .font(.caption)
            .foregroundStyle(theme.secondaryText)
            .multilineTextAlignment(.leading)
            .lineLimit(3)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
      }
    }
    .buttonStyle(.plain)
    .blocklistFilter(item.user.id, placeholder: false)
  }
}

struct GlassSubjectTopics: View {
  let subjectId: Int
  let topics: [TopicDTO]

  @AppStorage("hideBlocklist") var hideBlocklist: Bool = false
  @AppStorage("blocklist") var blocklist: [Int] = []
  @AppStorage("isAuthenticated") var isAuthenticated: Bool = false

  @Environment(\.theme) private var theme
  @State private var showCreateTopic: Bool = false

  private var visibleTopics: [TopicDTO] {
    topics.filter { !hideBlocklist || !blocklist.contains($0.creator?.id ?? 0) }
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 10) {
      ThemedSectionHeader("讨论版") {
        HStack(spacing: 10) {
          if isAuthenticated {
            Button {
              showCreateTopic = true
            } label: {
              Image(systemName: "plus.bubble")
                .font(.caption.weight(.bold))
                .foregroundStyle(theme.accent)
            }
            .buttonStyle(.plain)
          }
          if topics.count > 0 {
            NavigationLink(value: NavDestination.subjectTopicList(subjectId)) {
              GlassMoreLabel(title: "更多讨论 »")
            }
            .buttonStyle(.plain)
          }
        }
      }

      if visibleTopics.isEmpty {
        GlassSubjectEmptyRow(text: "暂无讨论")
      } else {
        CardView(padding: theme.metrics.cardPadding) {
          VStack(spacing: 0) {
            ForEach(visibleTopics) { topic in
              GlassSubjectTopicRow(topic: topic)
              if topic.id != visibleTopics.last?.id {
                ThemedDivider()
              }
            }
          }
        }
      }
    }
    .sheet(isPresented: $showCreateTopic) {
      CreateTopicBoxSheet(type: .subject(subjectId)) {
        Task {
          try? await SubjectRepository.loadSubjectDetails(subjectId, offprints: false, social: true)
        }
      }
    }
  }
}

struct GlassSubjectTopicRow: View {
  let topic: TopicDTO

  @Environment(\.theme) private var theme

  var body: some View {
    NavigationLink(value: NavDestination.subjectTopicDetail(topic.id)) {
      HStack(spacing: 10) {
        VStack(alignment: .leading, spacing: 3) {
          TopicTitleView(
            title: topic.title, createdAt: topic.createdAt, replyCount: topic.replyCount
          )
          .font(.footnote.weight(.bold))
          .foregroundStyle(theme.cardTitle)
          .multilineTextAlignment(.leading)
          .lineLimit(1)
          HStack(spacing: 4) {
            if let creator = topic.creator {
              Text(creator.nickname).lineLimit(1)
              Text(verbatim: "·")
            }
            Text(topic.createdAt.dateDisplay).lineLimit(1)
          }
          .font(.caption2)
          .monospacedDigit()
          .foregroundStyle(theme.placeholder)
        }
        Spacer(minLength: 0)
        if let count = topic.replyCount, count > 0 {
          Text("+\(count)")
            .font(.caption2.weight(.bold))
            .monospaced()
            .foregroundStyle(theme.onTintText)
            .padding(.horizontal, 8)
            .padding(.vertical, 2)
            .background(
              theme.tint,
              in: RoundedRectangle(cornerRadius: theme.metrics.cellRadius, style: .continuous)
            )
        }
      }
      .padding(.vertical, 10)
    }
    .buttonStyle(.plain)
    .blocklistFilter(topic.creator?.id ?? 0, placeholder: false)
  }
}

struct GlassSubjectComments: View {
  let subjectId: Int
  let subjectType: SubjectType
  let comments: [SubjectCommentDTO]

  @Environment(\.theme) private var theme

  var body: some View {
    VStack(alignment: .leading, spacing: 10) {
      ThemedSectionHeader("吐槽箱") {
        if comments.count > 0 {
          NavigationLink(value: NavDestination.subjectCommentList(subjectId)) {
            GlassMoreLabel(title: "更多吐槽 »")
          }
          .buttonStyle(.plain)
        }
      }

      if comments.isEmpty {
        GlassSubjectEmptyRow(text: "暂无吐槽")
      } else {
        CardView(padding: theme.metrics.cardPadding) {
          LazyVStack(spacing: 0) {
            ForEach(comments) { comment in
              GlassSubjectCommentRow(subjectType: subjectType, comment: comment)
              if comment.id != comments.last?.id {
                ThemedDivider()
              }
            }
          }
        }
      }
    }
  }
}

struct GlassSubjectCommentRow: View {
  let subjectType: SubjectType
  let comment: SubjectCommentDTO

  @Environment(\.theme) private var theme
  @State private var reactions: [ReactionDTO]

  init(subjectType: SubjectType, comment: SubjectCommentDTO) {
    self.subjectType = subjectType
    self.comment = comment
    self._reactions = State(initialValue: comment.reactions ?? [])
  }

  var body: some View {
    HStack(alignment: .top, spacing: 9) {
      ImageView(img: comment.user.avatar?.large)
        .imageStyle(width: 32, height: 32, cornerRadius: 16)
        .imageType(.avatar)
        .imageLink(comment.user.link)
      VStack(alignment: .leading, spacing: 4) {
        HStack(alignment: .firstTextBaseline, spacing: 6) {
          Text(comment.user.nickname.withLink(comment.user.link))
            .font(.caption.weight(.bold))
            .foregroundStyle(theme.cardTitle)
            .lineLimit(1)
          if comment.rate > 0 {
            StarsView(score: Float(comment.rate), size: 9)
          }
          Text(comment.type.description(subjectType))
            .font(.caption2)
            .foregroundStyle(theme.tertiaryText)
            .lineLimit(1)
          Spacer(minLength: 0)
          Text(comment.updatedAt.relativeDisplay)
            .font(.caption2)
            .monospacedDigit()
            .foregroundStyle(theme.tertiaryText)
            .lineLimit(1)
          ReactionButton(type: .subjectCollect(comment.id), reactions: $reactions)
            .font(.caption)
            .foregroundStyle(theme.tertiaryText)
        }
        Text(comment.comment)
          .font(.caption)
          .foregroundStyle(theme.secondaryText)
          .multilineTextAlignment(.leading)
          .textSelection(.enabled)
        if !reactions.isEmpty {
          ReactionsView(type: .subjectCollect(comment.id), reactions: $reactions)
        }
      }
      Spacer(minLength: 0)
    }
    .padding(.vertical, 11)
    .blocklistFilter(comment.user.id, placeholder: false)
  }
}

struct GlassSubjectFooter: View {
  let subjectId: Int

  @Environment(\.theme) private var theme

  var body: some View {
    Text(verbatim: "— 到底了 · subject/\(subjectId) —")
      .font(.caption2.weight(.semibold))
      .monospaced()
      .foregroundStyle(theme.placeholder)
      .frame(maxWidth: .infinity)
      .padding(.top, 6)
  }
}
