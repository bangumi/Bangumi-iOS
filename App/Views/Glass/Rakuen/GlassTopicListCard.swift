import SwiftUI

struct GlassReplyPill: View {
  let count: Int

  @Environment(\.theme) private var theme

  init(count: Int) {
    self.count = count
  }

  var body: some View {
    Text("+\(count)")
      .font(.caption2.weight(.bold).monospaced())
      .foregroundStyle(theme.onTintText)
      .padding(.horizontal, 9)
      .padding(.vertical, 4)
      .background(theme.tint, in: Capsule())
  }
}

struct GlassTopicRow<Source: View>: View {
  let avatar: String?
  let avatarLink: String?
  let title: String
  let createdAt: Int
  let updatedAt: Int
  let replyCount: Int
  let destination: NavDestination
  let source: Source

  @Environment(\.theme) private var theme

  init(
    avatar: String?,
    avatarLink: String?,
    title: String,
    createdAt: Int,
    updatedAt: Int,
    replyCount: Int,
    destination: NavDestination,
    @ViewBuilder source: () -> Source
  ) {
    self.avatar = avatar
    self.avatarLink = avatarLink
    self.title = title
    self.createdAt = createdAt
    self.updatedAt = updatedAt
    self.replyCount = replyCount
    self.destination = destination
    self.source = source()
  }

  var body: some View {
    HStack(alignment: .top, spacing: 11) {
      ImageView(img: avatar)
        .imageStyle(width: 38, height: 38, cornerRadius: 19, alignment: .center)
        .imageType(.avatar)
        .imageLink(avatarLink)
      VStack(alignment: .leading, spacing: 6) {
        NavigationLink(value: destination) {
          TopicTitleView(title: title, createdAt: createdAt, replyCount: replyCount)
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(theme.cardTitle)
            .lineLimit(2)
            .multilineTextAlignment(.leading)
        }
        .buttonStyle(.navigation)
        HStack(spacing: 6) {
          source
          Text("·")
            .font(.caption2)
            .foregroundStyle(theme.tertiaryText)
          Text(updatedAt.relativeDisplay)
            .font(.caption)
            .monospacedDigit()
            .foregroundStyle(theme.tertiaryText)
            .lineLimit(1)
        }
      }
      Spacer(minLength: 0)
      VStack(spacing: 0) {
        Spacer(minLength: 0)
        GlassReplyPill(count: replyCount)
        Spacer(minLength: 0)
      }
    }
    .padding(.vertical, 13)
    .padding(.horizontal, 14)
  }
}

struct GlassTopicListCard<Item: Identifiable, Row: View>: View {
  let items: [Item]
  let loading: Bool
  let exhausted: Bool
  let emptyTitle: String
  let emptyDescription: String
  let onRowAppear: (Item) -> Void
  let row: (Item) -> Row

  @Environment(\.theme) private var theme

  init(
    items: [Item],
    loading: Bool = false,
    exhausted: Bool = false,
    emptyTitle: String = "还没有话题",
    emptyDescription: String = "换一个筛选，或稍后再来看看",
    onRowAppear: @escaping (Item) -> Void = { _ in },
    @ViewBuilder row: @escaping (Item) -> Row
  ) {
    self.items = items
    self.loading = loading
    self.exhausted = exhausted
    self.emptyTitle = emptyTitle
    self.emptyDescription = emptyDescription
    self.onRowAppear = onRowAppear
    self.row = row
  }

  var body: some View {
    VStack(spacing: theme.metrics.listSpacing) {
      if items.isEmpty {
        if !loading {
          GlassEmptyCard(
            systemImage: "bubble.left.and.bubble.right",
            title: emptyTitle,
            description: emptyDescription)
        }
      } else {
        CardView(padding: 0) {
          LazyVStack(spacing: 0) {
            ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
              row(item)
                .transition(.opacity)
                .onAppear {
                  onRowAppear(item)
                }
              if index < items.count - 1 {
                Rectangle()
                  .fill(theme.separator)
                  .frame(height: 1)
                  .padding(.leading, 63)
              }
            }
          }
        }
      }
      if loading {
        HStack(spacing: 8) {
          ProgressView()
          Text("正在加载…")
            .font(.caption)
            .foregroundStyle(theme.tertiaryText)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 6)
      }
      if exhausted {
        VStack(spacing: 4) {
          MusumeView(width: 40)
          Text("没有更多了")
            .font(.caption)
            .foregroundStyle(theme.tertiaryText)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 6)
      }
    }
  }
}

struct GlassPagedTopicCard<Item, Row>: View
where Item: Identifiable & Codable & Sendable, Row: View {
  let limit: Int
  let reloader: Bool
  let isIncluded: (Item) -> Bool
  let nextPageFunc: (Int, Int) async -> PagedDTO<Item>?
  let row: (Item) -> Row

  @State private var loading = false
  @State private var offset = 0
  @State private var exhausted = false
  @State private var items: [Item] = []
  @State private var prefetchState = NextPagePrefetchState<Item.ID>()

  init(
    limit: Int = 20,
    reloader: Bool = false,
    isIncluded: @escaping (Item) -> Bool = { _ in true },
    nextPageFunc: @escaping (Int, Int) async -> PagedDTO<Item>?,
    @ViewBuilder row: @escaping (Item) -> Row
  ) {
    self.limit = limit
    self.reloader = reloader
    self.isIncluded = isIncluded
    self.nextPageFunc = nextPageFunc
    self.row = row
  }

  private func loadPage(currentOffset: Int) async -> [Item]? {
    guard let resp = await nextPageFunc(limit, currentOffset) else {
      return nil
    }
    if resp.data.isEmpty {
      exhausted = true
      return []
    }
    offset = currentOffset + limit
    if offset >= resp.total {
      exhausted = true
    }
    return resp.data
  }

  private func completeLoading() {
    loading = false
    prefetchState.completeLoading(canLoadMore: !exhausted)
  }

  private func reload() async {
    loading = true
    exhausted = false
    offset = 0
    prefetchState.reset()
    defer { completeLoading() }

    if let data = await loadPage(currentOffset: 0) {
      withAnimation(.default) {
        items = [Item]().mergedById(with: data)
      }
    }
  }

  private func loadNextPage() async {
    if loading { return }
    if exhausted { return }
    loading = true
    defer { completeLoading() }

    if let data = await loadPage(currentOffset: offset) {
      var transaction = Transaction()
      transaction.disablesAnimations = true
      withTransaction(transaction) {
        items = items.mergedById(with: data)
      }
    }
  }

  private func requestNextPage(for item: Item, in visibleItems: [Item]) {
    if prefetchState.request(
      item: item,
      in: visibleItems,
      isLoading: loading,
      canLoadMore: !exhausted
    ) != nil {
      Task {
        await loadNextPage()
      }
    }
  }

  var body: some View {
    let visibleItems = items.filter(isIncluded)

    GlassTopicListCard(
      items: visibleItems,
      loading: loading,
      exhausted: exhausted,
      onRowAppear: { item in
        requestNextPage(for: item, in: visibleItems)
      }
    ) { item in
      row(item)
    }
    .onAppear {
      if items.isEmpty {
        Task {
          await reload()
        }
      }
    }
    .onChange(of: reloader) { _, _ in
      Task {
        await reload()
      }
    }
  }
}

struct GlassRakuenTopicPage<Content: View>: View {
  let title: String
  @Binding var reloader: Bool
  let content: Content

  @Environment(\.theme) private var theme

  init(title: String, reloader: Binding<Bool>, @ViewBuilder content: () -> Content) {
    self.title = title
    self._reloader = reloader
    self.content = content()
  }

  var body: some View {
    ScrollView {
      content
        .padding(.horizontal, theme.metrics.screenPadding)
        .padding(.bottom, 26)
    }
    .navigationTitle(title)
    .navigationBarTitleDisplayMode(.inline)
    .refreshable {
      withAnimation(.default) {
        reloader.toggle()
      }
    }
  }
}

struct GlassRakuenSubjectTopicRow: View {
  let topic: SubjectTopicDTO

  @AppStorage("titlePreference") var titlePreference: TitlePreference = .original

  @Environment(\.theme) private var theme

  var body: some View {
    GlassTopicRow(
      avatar: topic.creator?.avatar?.large,
      avatarLink: topic.link,
      title: topic.title,
      createdAt: topic.createdAt,
      updatedAt: topic.updatedAt,
      replyCount: topic.replyCount,
      destination: .subjectTopicDetail(topic.id)
    ) {
      NavigationLink(value: NavDestination.subject(topic.subject.id)) {
        Text(topic.subject.title(with: titlePreference))
          .font(.caption.weight(.semibold))
          .foregroundStyle(theme.link)
          .lineLimit(1)
      }
      .buttonStyle(.scale)
    }
  }
}

struct GlassRakuenGroupTopicRow: View {
  let topic: GroupTopicDTO

  @Environment(\.theme) private var theme

  var body: some View {
    GlassTopicRow(
      avatar: topic.creator?.avatar?.large,
      avatarLink: topic.link,
      title: topic.title,
      createdAt: topic.createdAt,
      updatedAt: topic.updatedAt,
      replyCount: topic.replyCount,
      destination: .groupTopicDetail(topic.id)
    ) {
      NavigationLink(value: NavDestination.group(topic.group.name)) {
        Text(topic.group.title)
          .font(.caption.weight(.semibold))
          .foregroundStyle(theme.link)
          .lineLimit(1)
      }
      .buttonStyle(.scale)
    }
  }
}
