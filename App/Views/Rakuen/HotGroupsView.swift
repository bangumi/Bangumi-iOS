import SwiftData
import SwiftUI

struct HotGroupsView: View {
  @Environment(\.modelContext) private var modelContext
  @Query private var caches: [HotGroupCache]

  @State private var items: [SlimGroupDTO] = []
  @State private var loading = false
  @State private var initialized = false

  private var cachedItems: [SlimGroupDTO] {
    caches.first?.items ?? []
  }

  private var displayItems: [SlimGroupDTO] {
    items.isEmpty ? cachedItems : items
  }

  private func load() async {
    loading = true
    defer { loading = false }

    do {
      let resp = try await Chii.shared.getGroups(mode: .all, sort: .members, limit: 10)
      items = resp.data
      items.shuffle()

      // Save to cache
      let descriptor = FetchDescriptor<HotGroupCache>()
      if let existing = try? modelContext.fetch(descriptor).first {
        existing.items = items
        existing.updatedAt = Date()
      } else {
        let cache = HotGroupCache(items: items)
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
        }.frame(height: 120)
      }
    }
    .animation(.default, value: items)
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
