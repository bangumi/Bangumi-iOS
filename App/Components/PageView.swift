import SwiftUI

extension Array where Element: Identifiable {
  func nextPagePrefetchTrigger(prefetchWindow: Int = 5) -> NextPagePrefetchTrigger<Element.ID> {
    let triggerItems = suffix(Swift.max(prefetchWindow, 1))
    return NextPagePrefetchTrigger(
      triggerId: triggerItems.first?.id,
      itemIds: Set(triggerItems.map(\.id))
    )
  }

  func nextPagePrefetchTriggerId(for item: Element, prefetchWindow: Int = 5) -> Element.ID? {
    guard let itemIndex = firstIndex(where: { $0.id == item.id }) else {
      return nil
    }
    let triggerIndex = Swift.max(count - Swift.max(prefetchWindow, 1), 0)
    guard itemIndex >= triggerIndex else {
      return nil
    }
    return self[triggerIndex].id
  }
}

struct NextPagePrefetchTrigger<ID: Hashable> {
  let triggerId: ID?
  private let itemIds: Set<ID>

  init(triggerId: ID?, itemIds: Set<ID>) {
    self.triggerId = triggerId
    self.itemIds = itemIds
  }

  func triggerId(for itemId: ID) -> ID? {
    guard itemIds.contains(itemId) else {
      return nil
    }
    return triggerId
  }
}

struct NextPagePrefetchState<ID: Hashable> {
  private var requestedTriggerId: ID?

  mutating func reset() {
    requestedTriggerId = nil
  }

  mutating func request(triggerId: ID, isLoading: Bool, canLoadMore: Bool) -> Bool {
    guard canLoadMore else {
      reset()
      return false
    }
    guard !isLoading else {
      return false
    }
    guard requestedTriggerId != triggerId else {
      return false
    }

    requestedTriggerId = triggerId
    return true
  }

  mutating func request(
    trigger: NextPagePrefetchTaskKey<ID>,
    isLoading: Bool,
    canLoadMore: Bool
  ) -> ID? {
    guard let triggerId = trigger.triggerId else {
      return nil
    }
    guard
      request(
        triggerId: triggerId,
        isLoading: isLoading,
        canLoadMore: canLoadMore
      )
    else {
      return nil
    }
    return triggerId
  }

  mutating func request<Item: Identifiable>(
    item: Item,
    in items: [Item],
    isLoading: Bool,
    canLoadMore: Bool,
    prefetchWindow: Int = 5
  ) -> ID? where Item.ID == ID {
    guard
      let triggerId = items.nextPagePrefetchTriggerId(
        for: item,
        prefetchWindow: prefetchWindow
      )
    else {
      return nil
    }
    guard request(triggerId: triggerId, isLoading: isLoading, canLoadMore: canLoadMore) else {
      return nil
    }
    return triggerId
  }

  mutating func cancelRequest(triggerId: ID) {
    guard requestedTriggerId == triggerId else {
      return
    }
    requestedTriggerId = nil
  }

  mutating func completeLoading(canLoadMore: Bool) {
    if canLoadMore {
      requestedTriggerId = nil
    } else {
      reset()
    }
  }
}

struct NextPagePrefetchTaskKey<ID: Hashable>: Equatable {
  let triggerId: ID?
  let resetToken: Int

  init(
    triggerId: ID?,
    resetToken: Int = 0
  ) {
    self.triggerId = triggerId
    self.resetToken = resetToken
  }
}

/// A view that loads data continuously.
///
struct OffsetPagedView<T, C>: View
where C: View, T: Identifiable & Codable & Sendable {
  typealias Item = T
  typealias Content = C

  let limit: Int
  let reloader: Bool
  let isIncluded: (Item) -> Bool
  let nextPageFunc: (Int, Int) async -> PagedDTO<Item>?
  let content: (Item) -> Content

  @State private var loading: Bool = false
  @State private var offset: Int = 0
  @State private var exhausted: Bool = false
  @State private var items: [Item] = []
  @State private var prefetchState = NextPagePrefetchState<Item.ID>()

  func reload() {
    loading = true
    exhausted = false
    offset = 0
    prefetchState.reset()
    Task {
      defer { completeLoading() }
      let result = await loadPage(currentOffset: 0)
      if let newData = result {
        withAnimation {
          items = [Item]().mergedById(with: newData)
        }
      }
    }
  }

  func completeLoading() {
    loading = false
    prefetchState.completeLoading(canLoadMore: !exhausted)
  }

  func loadNextPage() async {
    if loading { return }
    if exhausted { return }
    loading = true
    defer { completeLoading() }
    let result = await loadPage(currentOffset: offset)
    if let newData = result {
      var transaction = Transaction()
      transaction.disablesAnimations = true
      withTransaction(transaction) {
        items = items.mergedById(with: newData)
      }
    }
  }

  private func loadPage(currentOffset: Int) async -> [Item]? {
    let resp = await nextPageFunc(limit, currentOffset)
    guard let resp = resp else {
      return nil
    }
    if resp.data.count == 0 {
      exhausted = true
      return []
    }
    offset = currentOffset + limit
    if offset >= resp.total {
      exhausted = true
    }
    return resp.data
  }

  public init(
    limit: Int = 20,
    reloader: Bool = false,
    isIncluded: @escaping (Item) -> Bool = { _ in true },
    nextPageFunc: @escaping (Int, Int) async -> PagedDTO<Item>?,
    @ViewBuilder content: @escaping (Item) -> Content
  ) {
    self.limit = limit
    self.nextPageFunc = nextPageFunc
    self.reloader = reloader
    self.isIncluded = isIncluded
    self.content = content
  }

  private func requestNextPage(for trigger: NextPagePrefetchTaskKey<Item.ID>) {
    if prefetchState.request(
      trigger: trigger,
      isLoading: loading,
      canLoadMore: !exhausted
    ) != nil {
      Task {
        await loadNextPage()
      }
    }
  }

  public var body: some View {
    let displayItems = items.filter(isIncluded)
    let nextPageTrigger = displayItems.nextPagePrefetchTrigger()

    LazyVStack(alignment: .leading) {
      ForEach(displayItems) { item in
        let trigger = NextPagePrefetchTaskKey(
          triggerId: nextPageTrigger.triggerId(for: item.id),
          resetToken: offset
        )
        content(item)
          .transition(.opacity)
          .task(id: trigger) {
            requestNextPage(for: trigger)
          }
      }

      if loading {
        HStack {
          Spacer()
          ProgressView()
          Spacer()
        }
      }

      if exhausted {
        HStack {
          Spacer()
          Text("没有更多了")
            .font(.footnote)
            .foregroundStyle(.secondary)
          Spacer()
        }
      }
    }
    .onAppear {
      if items.isEmpty {
        reload()
      }
    }
    .onChange(of: reloader) { _, _ in
      reload()
    }
  }
}

struct PageNumberPagedView<T, C>: View
where C: View, T: Identifiable & Codable & Sendable {
  typealias Item = T
  typealias Content = C

  let reloader: Bool
  let nextPageFunc: (Int) async -> PagedDTO<Item>?
  let content: (Item) -> Content

  @State private var loading: Bool = false
  @State private var page: Int = 1
  @State private var exhausted: Bool = false
  @State private var items: [Item] = []
  @State private var prefetchState = NextPagePrefetchState<Item.ID>()

  func reload() {
    loading = true
    exhausted = false
    page = 1
    prefetchState.reset()
    Task {
      defer { completeLoading() }
      let result = await loadPage(currentPage: 1)
      if let newData = result {
        withAnimation {
          items = [Item]().mergedById(with: newData)
        }
      }
    }
  }

  func completeLoading() {
    loading = false
    prefetchState.completeLoading(canLoadMore: !exhausted)
  }

  func loadNextPage() async {
    if loading { return }
    if exhausted { return }
    loading = true
    defer { completeLoading() }
    let result = await loadPage(currentPage: page)
    if let newData = result {
      var transaction = Transaction()
      transaction.disablesAnimations = true
      withTransaction(transaction) {
        items = items.mergedById(with: newData)
      }
    }
  }

  private func loadPage(currentPage: Int) async -> [Item]? {
    let resp = await nextPageFunc(currentPage)
    guard let resp = resp else {
      return nil
    }
    if resp.data.count == 0 {
      exhausted = true
      return []
    }
    let newData = resp.data
    page = currentPage + 1
    if page >= resp.total {
      exhausted = true
    }
    return newData
  }

  public init(
    reloader: Bool = false,
    nextPageFunc: @escaping (Int) async -> PagedDTO<Item>?,
    @ViewBuilder content: @escaping (Item) -> Content
  ) {
    self.nextPageFunc = nextPageFunc
    self.reloader = reloader
    self.content = content
  }

  private func requestNextPage(for trigger: NextPagePrefetchTaskKey<Item.ID>) {
    if prefetchState.request(
      trigger: trigger,
      isLoading: loading,
      canLoadMore: !exhausted
    ) != nil {
      Task {
        await loadNextPage()
      }
    }
  }

  public var body: some View {
    let nextPageTrigger = items.nextPagePrefetchTrigger()

    LazyVStack(alignment: .leading) {
      ForEach(items) { item in
        let trigger = NextPagePrefetchTaskKey(
          triggerId: nextPageTrigger.triggerId(for: item.id),
          resetToken: page
        )
        content(item)
          .transition(.opacity)
          .task(id: trigger) {
            requestNextPage(for: trigger)
          }
      }

      if loading {
        HStack {
          Spacer()
          ProgressView()
          Spacer()
        }
      }

      if exhausted {
        HStack {
          Spacer()
          Text("没有更多了")
            .font(.footnote)
            .foregroundStyle(.secondary)
          Spacer()
        }
      }
    }
    .onAppear {
      if items.isEmpty {
        reload()
      }
    }
    .onChange(of: reloader) { _, _ in
      reload()
    }
  }
}
