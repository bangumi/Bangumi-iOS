import SwiftData
import SwiftUI

struct HotGroupsView: View {
  @Environment(\.modelContext) private var modelContext
  @Query private var caches: [RakuenGroupCache]

  @State private var hotItems: [SlimGroupDTO] = []
  @State private var loading = false
  @State private var initialized = false

  private var hotCache: RakuenGroupCache? {
    caches.first { $0.id == "hot" }
  }

  private var pinCache: RakuenGroupCache? {
    caches.first { $0.id == "pin" }
  }

  private var pinnedItems: [SlimGroupDTO] {
    pinCache?.items ?? []
  }

  private var cachedHotItems: [SlimGroupDTO] {
    hotCache?.items ?? []
  }

  private var hotDisplayItems: [SlimGroupDTO] {
    hotItems.isEmpty ? cachedHotItems : hotItems
  }

  // Display pinned first, then hot groups (excluding duplicates)
  private var displayItems: [SlimGroupDTO] {
    let pinnedIds = Set(pinnedItems.map(\.id))
    let filteredHot = hotDisplayItems.filter { !pinnedIds.contains($0.id) }
    return pinnedItems + filteredHot
  }

  private func isPinned(_ group: SlimGroupDTO) -> Bool {
    pinnedItems.contains { $0.id == group.id }
  }

  private func togglePin(_ group: SlimGroupDTO) {
    if isPinned(group) {
      // Unpin
      if let cache = pinCache {
        cache.items.removeAll { $0.id == group.id }
        cache.updatedAt = Date()
        try? modelContext.save()
      }
    } else {
      // Pin
      if let cache = pinCache {
        cache.items.insert(group, at: 0)
        cache.updatedAt = Date()
      } else {
        let cache = RakuenGroupCache(id: "pin", items: [group])
        modelContext.insert(cache)
      }
      try? modelContext.save()
    }
  }

  private func load() async {
    loading = true
    defer { loading = false }

    do {
      let resp = try await Chii.shared.getGroups(mode: .all, sort: .members, limit: 10)
      hotItems = resp.data
      hotItems.shuffle()

      // Save to hot cache
      if let existing = hotCache {
        existing.items = hotItems
        existing.updatedAt = Date()
      } else {
        let cache = RakuenGroupCache(id: "hot", items: hotItems)
        modelContext.insert(cache)
      }
      try? modelContext.save()
    } catch {
      Notifier.shared.alert(error: error)
    }
  }

  var body: some View {
    VStack(alignment: .leading) {
      if !displayItems.isEmpty {
        HStack {
          Text("热门小组").font(.title3)
          Spacer()
        }.padding(.top, 8)
        ScrollView(.horizontal, showsIndicators: false) {
          LazyHStack {
            ForEach(displayItems) { group in
              VStack {
                ImageView(img: group.icon?.large)
                  .imageStyle(width: 80, height: 80)
                  .imageType(.icon)
                  .imageLink(group.link)
                  .overlay(alignment: .topLeading) {
                    if isPinned(group) {
                      Image(systemName: "pin.fill")
                        .font(.caption2)
                        .foregroundStyle(.white)
                        .padding(3)
                        .background(.orange, in: Circle())
                        .shadow(radius: 2)
                        .padding(.top, 3)
                        .padding(.leading, 3)
                    }
                  }
                  .contextMenu {
                    Button {
                      togglePin(group)
                    } label: {
                      if isPinned(group) {
                        Label("取消置顶", systemImage: "pin.slash")
                      } else {
                        Label("置顶", systemImage: "pin")
                      }
                    }
                  }
                Text(group.title)
                  .lineLimit(2)
                  .font(.footnote)
                  .foregroundStyle(.secondary)
                Text("\(group.members ?? 0) 位成员")
                  .font(.caption)
                  .foregroundStyle(.secondary)
              }.frame(width: 80, height: 120)
            }
          }
        }
        .scrollClipDisabled()
        .frame(height: 120)
      }
    }
    .animation(.default, value: displayItems.map(\.id))
    .onAppear {
      if !initialized {
        initialized = true
        Task {
          await load()
        }
      }
    }
  }
}
