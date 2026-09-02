import SwiftUI

struct GlassHotGroupsRow: View {
  let groups: [SlimGroupDTO]
  let isPinned: (SlimGroupDTO) -> Bool
  let togglePin: (SlimGroupDTO) -> Void

  @Environment(\.theme) private var theme

  init(
    groups: [SlimGroupDTO],
    isPinned: @escaping (SlimGroupDTO) -> Bool,
    togglePin: @escaping (SlimGroupDTO) -> Void
  ) {
    self.groups = groups
    self.isPinned = isPinned
    self.togglePin = togglePin
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 10) {
      if !groups.isEmpty {
        ThemedSectionHeader("热门小组", systemImage: "flame.fill") {
          Text("长按置顶 · 每次随机排序")
            .font(.caption)
            .foregroundStyle(theme.tertiaryText)
        }
        ScrollView(.horizontal, showsIndicators: false) {
          LazyHStack(alignment: .top, spacing: 10) {
            ForEach(groups) { group in
              column(group)
            }
          }
          .padding(.vertical, 2)
        }
        .scrollClipDisabled()
      }
    }
  }

  private func column(_ group: SlimGroupDTO) -> some View {
    VStack(spacing: 5) {
      ImageView(img: group.icon?.large)
        .imageStyle(width: 52, height: 52, alignment: .center)
        .imageType(.icon)
        .imageNSFW(group.nsfw)
        .imageLink(group.link)
        .overlay(alignment: .topTrailing) {
          if isPinned(group) {
            pinBadge
          }
        }
        .contextMenu {
          Button {
            togglePin(group)
          } label: {
            if isPinned(group) {
              Label("取消置顶", systemImage: "pin.slash")
            } else {
              Label("置顶小组", systemImage: "pin")
            }
          }
          NavigationLink(value: NavDestination.group(group.name)) {
            Label("进入小组", systemImage: "arrow.up.right")
          }
        }
      Text(group.title)
        .font(.caption.weight(.semibold))
        .foregroundStyle(theme.sectionHeader)
        .lineLimit(1)
      Text("\(glassCompactCount(group.members ?? 0)) 位成员")
        .font(.caption2.weight(.semibold).monospaced())
        .foregroundStyle(theme.tertiaryText)
        .lineLimit(1)
    }
    .frame(width: 64)
  }

  private var pinBadge: some View {
    Image(systemName: "pin.fill")
      .font(.system(size: 9, weight: .bold))
      .foregroundStyle(theme.accent)
      .frame(width: 19, height: 19)
      .background(theme.cardFillOpaque, in: Circle())
      .overlay {
        Circle().strokeBorder(theme.badgeRing, lineWidth: 1)
      }
      .shadow(color: theme.cardShadow.color, radius: 4, y: 2)
      .offset(x: 5, y: -5)
  }
}
