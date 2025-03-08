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
  @State private var loadedIdx: [Int: Bool] = [:]
  @State private var items: [EnumerateItem<(Item)>] = []

  func reload() {
    exhausted = false
    loadedIdx = [:]
    Task {
      let result = await loadPage(currentOffset: 0)
      if let newData = result {
        items = newData
      }
    }
  }

  func loadNextPage(idx: Int) async {
    if loading { return }
    if exhausted { return }
    if idx > 0 && idx != offset - 5 { return }
    if loadedIdx[idx, default: false] { return }
    loadedIdx[idx] = true
    loading = true
    defer { loading = false }
    let result = await loadPage(currentOffset: offset)
    if let newData = result {
      items.append(contentsOf: newData)
    }
  }

  private func loadPage(currentOffset: Int) async -> [EnumerateItem<Item>]? {
    let resp = await nextPageFunc(limit, currentOffset)
    guard let resp = resp else {
      return nil
    }
    if resp.data.count == 0 {
      exhausted = true
      return []
    }
    let newData = resp.data.enumerated().map { (idx, item) in
      EnumerateItem(idx: idx + currentOffset, inner: item)
    }
    offset = currentOffset + limit
    if offset >= resp.total {
      exhausted = true
    }
    return newData
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
        content(item.inner).onAppear {
          Task {
            await loadNextPage(idx: item.idx)
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
