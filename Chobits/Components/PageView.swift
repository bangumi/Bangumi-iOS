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
    offset = 0
    exhausted = false
    loadedIdx = [:]
    items = []
    Task {
      await loadNextPage(idx: 0)
    }
  }

  func loadNextPage(idx: Int) async {
    if exhausted {
      return
    }
    if idx > 0 && idx != offset - 5 {
      return
    }
    if loadedIdx[idx, default: false] {
      return
    }
    loading = true
    loadedIdx[idx] = true
    let resp = await nextPageFunc(limit, offset)
    guard let resp = resp else {
      loading = false
      return
    }
    if resp.data.count < limit {
      exhausted = true
    }
    let data = resp.data.enumerated().map { (idx, item) in
      EnumerateItem(idx: idx + offset, inner: item)
    }
    offset += limit
    if offset >= resp.total {
      exhausted = true
    }
    items.append(contentsOf: data)
    loading = false
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
    LazyVStack {
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
