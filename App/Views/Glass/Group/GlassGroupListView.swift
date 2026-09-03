import SwiftUI

struct GlassGroupListView: View {
  let mode: GroupFilterMode
  @Binding var sortMode: GroupSortMode
  @Binding var reloader: Bool
  let load: (Int, Int) async -> PagedDTO<SlimGroupDTO>?

  @Environment(\.theme) private var theme

  init(
    mode: GroupFilterMode,
    sortMode: Binding<GroupSortMode>,
    reloader: Binding<Bool>,
    load: @escaping (Int, Int) async -> PagedDTO<SlimGroupDTO>?
  ) {
    self.mode = mode
    self._sortMode = sortMode
    self._reloader = reloader
    self.load = load
  }

  var body: some View {
    ScrollView {
      OffsetPagedView(reloader: reloader, nextPageFunc: load) { (group: SlimGroupDTO) in
        groupCard(group)
      }
      .padding(.horizontal, theme.metrics.screenPadding)
      .padding(.bottom, 26)
    }
    .navigationTitle(mode.title)
    .toolbar {
      ToolbarItem(placement: .topBarTrailing) {
        Menu {
          ForEach(GroupSortMode.allCases, id: \.self) { item in
            Button {
              withAnimation(.default) {
                sortMode = item
                reloader.toggle()
              }
            } label: {
              if sortMode == item {
                Label(item.description, systemImage: "checkmark")
              } else {
                Text(item.description)
              }
            }
          }
        } label: {
          ToolbarCircle {
            Image(systemName: "arrow.up.arrow.down")
              .font(.callout.weight(.semibold))
          }
        }
      }
    }
  }

  private func groupCard(_ group: SlimGroupDTO) -> some View {
    CardView(padding: theme.metrics.cardPadding) {
      HStack(alignment: .top, spacing: 12) {
        ImageView(img: group.icon?.large)
          .imageStyle(width: 52, height: 52, alignment: .center)
          .imageType(.icon)
          .imageNSFW(group.nsfw)
          .imageLink(group.link)
        VStack(alignment: .leading, spacing: 6) {
          NavigationLink(value: NavDestination.group(group.name)) {
            Text(group.title)
              .font(.subheadline.weight(.bold))
              .foregroundStyle(theme.cardTitle)
              .lineLimit(2)
              .multilineTextAlignment(.leading)
          }
          .buttonStyle(.navigation)
          if let members = group.members {
            metaLabel("person.2", "\(members) 位成员")
          }
          if let createdAt = group.createdAt {
            metaLabel("calendar", "创建时间: \(createdAt.datetimeDisplay)")
          }
        }
        Spacer(minLength: 0)
      }
    }
  }

  private func metaLabel(_ icon: String, _ text: String) -> some View {
    HStack(spacing: 4) {
      Image(systemName: icon)
        .font(.caption2)
      Text(text)
        .font(.caption)
        .monospacedDigit()
        .lineLimit(1)
    }
    .foregroundStyle(theme.secondaryText)
  }
}
