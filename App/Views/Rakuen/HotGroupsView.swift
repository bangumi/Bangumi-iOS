import OSLog
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
    Task {
      do {
        let db = try await Chii.shared.getDB()
        try await db.togglePinRakuenGroupCache(group: group)
      } catch {
        Logger.app.error("Failed to toggle pin: \(error)")
      }
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
      if let db = try? await Chii.shared.getDB() {
        try await db.saveRakuenGroupCache(id: "hot", items: hotItems)
      }
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
