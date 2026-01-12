import SwiftData
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
      let resp = try await Chii.shared.getRecentGroupTopics(
        mode: mode, limit: limit, offset: offset)
      return resp
    } catch {
      Notifier.shared.alert(error: error)
      return nil
    }
  }

  var body: some View {
    PageView<GroupTopicDTO, _>(reloader: reloader, nextPageFunc: load) { topic in
      if !hideBlocklist || !blocklist.contains(topic.creator?.id ?? 0) {
        RakuenGroupTopicItemView(topic: topic)
      }
    }
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
            topic.updatedAt.relativeText
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

  @Query private var caches: [RakuenGroupTopicCache]

  @AppStorage("hideBlocklist") var hideBlocklist: Bool = false
  @AppStorage("blocklist") var blocklist: [Int] = []

  @State private var items: [GroupTopicDTO] = []
  @State private var loading = false
  @State private var offset = 0
  @State private var exhausted = false
  @State private var initialized = false

  private var cachedItems: [GroupTopicDTO] {
    caches.first { $0.mode == mode.rawValue }?.items ?? []
  }

  private var displayItems: [GroupTopicDTO] {
    items.isEmpty ? cachedItems : items
  }

  private var filteredItems: [GroupTopicDTO] {
    if hideBlocklist {
      return displayItems.filter { !blocklist.contains($0.creator?.id ?? 0) }
    }
    return displayItems
  }

  private func shouldLoadMore(after item: GroupTopicDTO, threshold: Int = 5) -> Bool {
    displayItems.suffix(threshold).contains(item)
  }

  private func loadFirstPage() async {
    if loading { return }
    loading = true
    defer { loading = false }

    do {
      let resp = try await Chii.shared.getRecentGroupTopics(mode: mode, limit: 20, offset: 0)
      items = resp.data
      offset = 20
      exhausted = resp.data.count == 0 || offset >= resp.total

      // Save to cache
      if let db = try? await Chii.shared.getDB() {
        try await db.saveRakuenGroupTopicCache(mode: mode.rawValue, items: resp.data)
      }
    } catch {
      Notifier.shared.alert(error: error)
    }
  }

  private func loadNextPage() async {
    if loading || exhausted { return }
    loading = true
    defer { loading = false }

    do {
      let resp = try await Chii.shared.getRecentGroupTopics(mode: mode, limit: 20, offset: offset)
      items.append(contentsOf: resp.data)
      offset += 20
      if resp.data.count == 0 || offset >= resp.total {
        exhausted = true
      }
    } catch {
      Notifier.shared.alert(error: error)
    }
  }

  var body: some View {
    LazyVStack(alignment: .leading) {
      ForEach(filteredItems) { topic in
        RakuenGroupTopicItemView(topic: topic)
          .onAppear {
            if shouldLoadMore(after: topic) {
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
    .animation(.default, value: items)
    .onAppear {
      if !initialized {
        initialized = true
        Task {
          await loadFirstPage()
        }
      }
    }
    .onChange(of: mode) { _, _ in
      items = []
      offset = 0
      exhausted = false
      loading = false
      Task {
        await loadFirstPage()
      }
    }
    .onChange(of: reloader) { _, _ in
      exhausted = false
      offset = 0
      initialized = false
      Task {
        await loadFirstPage()
      }
    }
  }
}
