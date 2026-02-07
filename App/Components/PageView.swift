import SwiftUI

/// A view that loads data continuously.
///
struct PageView<T, C>: View
where C: View, T: Identifiable & Hashable & Codable & Sendable {
  typealias Item = T
  typealias Content = C

  let limit: Int
  let reloader: Bool
  let nextPageFunc: (Int, Int) async -> PagedDTO<Item>?
  let content: (Item) -> Content

  @State private var loading: Bool = false
  @State private var offset: Int = 0
  @State private var exhausted: Bool = false
  @State private var items: [Item] = []

  private func shouldLoadMore(after item: Item, threshold: Int = 5) -> Bool {
    items.suffix(threshold).contains(item)
  }

  func reload() {
    loading = true
    exhausted = false
    offset = 0
    Task {
      defer { loading = false }
      let result = await loadPage(currentOffset: 0)
      if let newData = result {
        items = newData
      }
    }
  }

  func loadNextPage() async {
    if loading { return }
    if exhausted { return }
    loading = true
    defer { loading = false }
    let result = await loadPage(currentOffset: offset)
    if let newData = result {
      items.append(contentsOf: newData)
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
    nextPageFunc: @escaping (Int, Int) async -> PagedDTO<Item>?,
    @ViewBuilder content: @escaping (Item) -> Content
  ) {
    self.limit = limit
    self.nextPageFunc = nextPageFunc
    self.reloader = reloader
    self.content = content
  }

  public var body: some View {
    LazyVStack(alignment: .leading) {
      ForEach(items) { item in
        content(item).onAppear {
          if shouldLoadMore(after: item) {
            Task {
              await loadNextPage()
            }
          }
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
    .animation(.default, value: reloader)
    .animation(.default, value: items)
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

struct SimplePageView<T, C>: View
where C: View, T: Identifiable & Hashable & Codable & Sendable {
  typealias Item = T
  typealias Content = C

  let reloader: Bool
  let nextPageFunc: (Int) async -> PagedDTO<Item>?
  let content: (Item) -> Content

  @State private var loading: Bool = false
  @State private var page: Int = 1
  @State private var exhausted: Bool = false
  @State private var items: [Item] = []

  func reload() {
    loading = true
    exhausted = false
    page = 1
    Task {
      defer { loading = false }
      let result = await loadPage(currentPage: 1)
      if let newData = result {
        items = newData
      }
    }
  }

  func loadNextPage() async {
    if loading { return }
    if exhausted { return }
    loading = true
    defer { loading = false }
    let result = await loadPage(currentPage: page)
    if let newData = result {
      items.append(contentsOf: newData)
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

  public var body: some View {
    LazyVStack(alignment: .leading) {
      ForEach(items) { item in
        content(item)
          .onAppear {
            if item == items.last {
              Task {
                await loadNextPage()
              }
            }
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
    .animation(.default, value: reloader)
    .animation(.default, value: items)
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

#Preview {
  func nextPage(page: Int, size: Int) async -> PagedDTO<EpisodeDTO>? {
    let episodes = loadFixture(
      fixture: "subject_episodes.json",
      target: PagedDTO<EpisodeDTO>.self
    )
    return episodes
  }

  return ScrollView {
    PageView<EpisodeDTO, _>(nextPageFunc: nextPage) { item in
      VStack {
        Text("\(item.id): \(item.name)")
        Divider()
      }
    }
  }.padding()
}
