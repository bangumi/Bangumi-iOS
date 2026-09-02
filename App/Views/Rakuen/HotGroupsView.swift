import OSLog
import SwiftUI

struct HotGroupsView: View {
  @State private var hotItems: [SlimGroupDTO] = []
  @State private var cachedHotItems: [SlimGroupDTO] = []
  @State private var pinnedItems: [SlimGroupDTO] = []
  @State private var loading = false
  @State private var initialized = false

  @Environment(\.theme) private var theme

  private var iconSize: CGFloat {
    theme.isClassic ? 80 : 56
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
        let db = try await AppContext.shared.getDB()
        try await db.togglePinRakuenGroupCache(group: group)
        let fetchedPins = try await db.fetchRakuenGroupCache(id: "pin")
        withAnimation(.default) {
          pinnedItems = fetchedPins
        }
      } catch {
        Logger.app.error("Failed to toggle pin: \(error)")
      }
    }
  }

  private func loadCache() async {
    do {
      let db = try await AppContext.shared.getDB()
      let fetchedCachedItems = try await db.fetchRakuenGroupCache(id: "hot")
      let fetchedPinnedItems = try await db.fetchRakuenGroupCache(id: "pin")
      withAnimation(.default) {
        cachedHotItems = fetchedCachedItems
        pinnedItems = fetchedPinnedItems
      }
    } catch {
      Logger.app.error("Failed to load group cache: \(error)")
    }
  }

  private func load() async {
    withAnimation(.default) {
      loading = true
    }
    defer {
      withAnimation(.default) {
        loading = false
      }
    }

    do {
      let resp = try await GroupService.getGroups(mode: .all, sort: .members, limit: 10)
      var fetchedItems = resp.data
      fetchedItems.shuffle()
      withAnimation(.default) {
        hotItems = fetchedItems
      }

      // Save to hot cache
      if let db = try? await AppContext.shared.getDB() {
        try await db.saveRakuenGroupCache(id: "hot", items: fetchedItems)
        withAnimation(.default) {
          cachedHotItems = fetchedItems
        }
      }
    } catch {
      Notifier.shared.alert(error: error)
    }
  }

  var body: some View {
    VStack(alignment: .leading) {
      if !displayItems.isEmpty {
        headerView.padding(.top, 8)
        ScrollView(.horizontal, showsIndicators: false) {
          LazyHStack {
            ForEach(Array(displayItems.enumerated()), id: \.element.id) { index, group in
              VStack {
                groupIcon(group, index: index)
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
    .onAppear {
      if !initialized {
        initialized = true
        Task {
          await loadCache()
          await load()
        }
      }
    }
  }

  @ViewBuilder
  private var headerView: some View {
    if theme.isClassic {
      HStack {
        Text("热门小组").font(.title3)
        Spacer()
      }
    } else {
      ThemedSectionHeader("热门小组")
    }
  }

  @ViewBuilder
  private func groupIcon(_ group: SlimGroupDTO, index: Int) -> some View {
    let icon = ImageView(img: group.icon?.large)
      .imageStyle(width: iconSize, height: iconSize)
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
    if theme.isClassic {
      icon
    } else {
      icon.shadow(color: iconShadow(index), radius: 8, y: 4)
    }
  }

  private func iconShadow(_ index: Int) -> Color {
    let gradients = theme.avatarGradients
    guard !gradients.isEmpty else {
      return .clear
    }
    let colors = gradients[index % gradients.count]
    return (colors.last ?? .clear).opacity(0.22)
  }
}
