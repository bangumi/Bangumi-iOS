import SwiftUI

struct RakuenGroupTopicView: View {
  let mode: GroupTopicFilterMode

  @State private var reloader = false

  var body: some View {
    ScrollView {
      RakuenGroupTopicListView(mode: mode, reloader: $reloader)
        .padding(.horizontal, 8)
    }
    .navigationTitle(mode.title)
    .navigationBarTitleDisplayMode(.inline)
    .refreshable {
      reloader.toggle()
    }
  }
}

struct RakuenGroupTopicListView: View {
  let mode: GroupTopicFilterMode
  @Binding var reloader: Bool

  @AppStorage("hideBlocklist") var hideBlocklist: Bool = false
  @AppStorage("blocklist") var blocklist: [Int] = []

  private func load(limit: Int, offset: Int) async -> PagedDTO<GroupTopicDTO>? {
    do {
      let resp = try await TopicService.getRecentGroupTopics(
        mode: mode, limit: limit, offset: offset)
      return resp
    } catch {
      Notifier.shared.alert(error: error)
      return nil
    }
  }

  var body: some View {
    OffsetPagedView<GroupTopicDTO, _>(
      reloader: reloader,
      isIncluded: isVisible,
      nextPageFunc: load
    ) { topic in
      RakuenGroupTopicItemView(topic: topic)
    }
  }

  private func isVisible(_ topic: GroupTopicDTO) -> Bool {
    !hideBlocklist || !blocklist.contains(topic.creator?.id ?? 0)
  }
}

struct RakuenGroupTopicItemView: View {
  let topic: GroupTopicDTO

  var body: some View {
    CardView {
      HStack(alignment: .top) {
        ImageView(img: topic.creator?.avatar?.large)
          .imageStyle(width: 40, height: 40)
          .imageType(.avatar)
          .imageLink(topic.link)
        VStack(alignment: .leading) {
          Section {
            Text(topic.title.withLink(topic.link))
              .font(.headline)
              + Text("(+\(topic.replyCount))")
              .font(.footnote)
              .foregroundStyle(.secondary)
          }
          HStack {
            Text(topic.updatedAt.relativeDisplay).monospacedDigit()
              .font(.caption)
              .foregroundStyle(.secondary)
              .lineLimit(1)
            Spacer()
            NavigationLink(value: NavDestination.group(topic.group.name)) {
              Text(topic.group.title)
                .font(.footnote)
                .lineLimit(1)
            }.buttonStyle(.scale)
          }
        }
        Spacer()
      }
    }
  }
}

struct CachedGroupTopicListView: View {
  let mode: GroupTopicFilterMode
  @Binding var reloader: Bool

  @AppStorage("hideBlocklist") var hideBlocklist: Bool = false
  @AppStorage("blocklist") var blocklist: [Int] = []

  @State private var items: [GroupTopicDTO] = []
  @State private var cachedItems: [GroupTopicDTO] = []
  @State private var loading = false
  @State private var offset = 0
  @State private var exhausted = false
  @State private var initialized = false
  @State private var prefetchState = NextPagePrefetchState<GroupTopicDTO.ID>()

  private var displayItems: [GroupTopicDTO] {
    items.isEmpty ? cachedItems : items
  }

  private func loadCache() async {
    do {
      let db = try await AppContext.shared.getDB()
      cachedItems = try await db.fetchRakuenGroupTopicCache(mode: mode.rawValue)
    } catch {
      cachedItems = []
    }
  }

  private func loadFirstPage() async {
    if loading { return }
    loading = true
    prefetchState.reset()
    defer { completeLoading() }

    do {
      let resp = try await TopicService.getRecentGroupTopics(mode: mode, limit: 20, offset: 0)
      withAnimation {
        items = [GroupTopicDTO]().mergedById(with: resp.data)
      }
      offset = 20
      exhausted = resp.data.count == 0 || offset >= resp.total

      // Save to cache
      if let db = try? await AppContext.shared.getDB() {
        try await db.saveRakuenGroupTopicCache(mode: mode.rawValue, items: resp.data)
        cachedItems = resp.data
      }
    } catch {
      Notifier.shared.alert(error: error)
    }
  }

  private func completeLoading() {
    loading = false
    prefetchState.completeLoading(canLoadMore: !exhausted)
  }

  private func loadNextPage() async {
    if loading { return }
    if exhausted { return }
    loading = true
    defer { completeLoading() }

    do {
      let resp = try await TopicService.getRecentGroupTopics(mode: mode, limit: 20, offset: offset)
      items = items.mergedById(with: resp.data)
      offset += 20
      if resp.data.count == 0 || offset >= resp.total {
        exhausted = true
      }
    } catch {
      Notifier.shared.alert(error: error)
    }
  }

  private func requestNextPage(for item: GroupTopicDTO, in visibleItems: [GroupTopicDTO]) {
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
    let visibleItems = displayItems.filter(isVisible)

    LazyVStack(alignment: .leading) {
      ForEach(visibleItems) { item in
        RakuenGroupTopicItemView(topic: item)
          .transition(.opacity)
          .onAppear {
            requestNextPage(for: item, in: visibleItems)
          }
      }

      if loading {
        HStack {
          Spacer()
          ProgressView()
          Spacer()
        }.padding()
      }

      if exhausted {
        VStack {
          Text("没有更多了")
            .font(.footnote)
            .foregroundStyle(.secondary)
          MusumeView(width: 40)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical)
      }
    }
    .onAppear {
      if !initialized {
        initialized = true
        Task {
          await loadCache()
          await loadFirstPage()
        }
      }
    }
    .onChange(of: mode) { _, _ in
      items = []
      offset = 0
      exhausted = false
      loading = false
      prefetchState.reset()
      Task {
        await loadCache()
        await loadFirstPage()
      }
    }
    .onChange(of: reloader) { _, _ in
      exhausted = false
      offset = 0
      initialized = false
      prefetchState.reset()
      Task {
        await loadCache()
        await loadFirstPage()
      }
    }
  }

  private func isVisible(_ topic: GroupTopicDTO) -> Bool {
    !hideBlocklist || !blocklist.contains(topic.creator?.id ?? 0)
  }
}
