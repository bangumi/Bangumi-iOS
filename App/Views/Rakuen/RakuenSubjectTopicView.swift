import SwiftUI

struct RakuenSubjectTopicView: View {
  let mode: SubjectTopicFilterMode

  @AppStorage("titlePreference") var titlePreference: TitlePreference = .original

  @State private var reloader = false

  var body: some View {
    ScrollView {
      RakuenSubjectTopicListView(mode: mode, reloader: $reloader)
        .padding(.horizontal, 8)
    }
    .navigationTitle(mode.title)
    .navigationBarTitleDisplayMode(.inline)
    .refreshable {
      reloader.toggle()
    }
  }
}

struct RakuenSubjectTopicListView: View {
  let mode: SubjectTopicFilterMode
  @Binding var reloader: Bool

  @AppStorage("hideBlocklist") var hideBlocklist: Bool = false
  @AppStorage("blocklist") var blocklist: [Int] = []

  private func load(limit: Int, offset: Int) async -> PagedDTO<SubjectTopicDTO>? {
    do {
      switch mode {
      case .trending:
        let resp = try await TopicService.getTrendingSubjectTopics(limit: limit, offset: offset)
        return resp
      case .latest:
        let resp = try await TopicService.getRecentSubjectTopics(limit: limit, offset: offset)
        return resp
      }
    } catch {
      Notifier.shared.alert(error: error)
      return nil
    }
  }

  var body: some View {
    OffsetPagedView<SubjectTopicDTO, _>(
      reloader: reloader,
      isIncluded: isVisible,
      nextPageFunc: load
    ) { topic in
      RakuenSubjectTopicItemView(topic: topic)
    }
  }

  private func isVisible(_ topic: SubjectTopicDTO) -> Bool {
    !hideBlocklist || !blocklist.contains(topic.creator?.id ?? 0)
  }
}

struct RakuenSubjectTopicItemView: View {
  let topic: SubjectTopicDTO

  @AppStorage("titlePreference") var titlePreference: TitlePreference = .original

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
            NavigationLink(value: NavDestination.subject(topic.subject.id)) {
              Text(topic.subject.title(with: titlePreference))
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

struct CachedSubjectTopicListView: View {
  let mode: SubjectTopicFilterMode
  @Binding var reloader: Bool

  @AppStorage("hideBlocklist") var hideBlocklist: Bool = false
  @AppStorage("blocklist") var blocklist: [Int] = []

  @State private var items: [SubjectTopicDTO] = []
  @State private var cachedItems: [SubjectTopicDTO] = []
  @State private var loading = false
  @State private var offset = 0
  @State private var exhausted = false
  @State private var initialized = false
  @State private var prefetchState = NextPagePrefetchState<SubjectTopicDTO.ID>()

  private var displayItems: [SubjectTopicDTO] {
    items.isEmpty ? cachedItems : items
  }

  private func loadCache() async {
    do {
      let db = try await AppContext.shared.getDB()
      cachedItems = try await db.fetchRakuenSubjectTopicCache(mode: mode.rawValue)
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
      let resp: PagedDTO<SubjectTopicDTO>?
      switch mode {
      case .trending:
        resp = try await TopicService.getTrendingSubjectTopics(limit: 20, offset: 0)
      case .latest:
        resp = try await TopicService.getRecentSubjectTopics(limit: 20, offset: 0)
      }
      if let resp = resp {
        withAnimation {
          items = [SubjectTopicDTO]().mergedById(with: resp.data)
        }
        offset = 20
        exhausted = resp.data.count == 0 || offset >= resp.total

        // Save to cache
        if let db = try? await AppContext.shared.getDB() {
          try await db.saveRakuenSubjectTopicCache(mode: mode.rawValue, items: resp.data)
          cachedItems = resp.data
        }
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
      let resp: PagedDTO<SubjectTopicDTO>?
      switch mode {
      case .trending:
        resp = try await TopicService.getTrendingSubjectTopics(limit: 20, offset: offset)
      case .latest:
        resp = try await TopicService.getRecentSubjectTopics(limit: 20, offset: offset)
      }
      if let resp = resp {
        items = items.mergedById(with: resp.data)
        offset += 20
        if resp.data.count == 0 || offset >= resp.total {
          exhausted = true
        }
      }
    } catch {
      Notifier.shared.alert(error: error)
    }
  }

  private func requestNextPage(for item: SubjectTopicDTO, in visibleItems: [SubjectTopicDTO]) {
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
        RakuenSubjectTopicItemView(topic: item)
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

  private func isVisible(_ topic: SubjectTopicDTO) -> Bool {
    !hideBlocklist || !blocklist.contains(topic.creator?.id ?? 0)
  }
}
