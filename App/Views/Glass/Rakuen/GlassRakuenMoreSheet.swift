import SwiftUI

struct GlassRakuenMoreItem: Identifiable {
  let title: String
  let icon: String
  let requiresLogin: Bool
  let destination: NavDestination

  var id: NavDestination {
    destination
  }
}

struct GlassRakuenMoreSheet: View {
  let isAuthenticated: Bool
  let onSelect: (NavDestination) -> Void

  @Environment(\.theme) private var theme

  init(isAuthenticated: Bool, onSelect: @escaping (NavDestination) -> Void) {
    self.isAuthenticated = isAuthenticated
    self.onSelect = onSelect
  }

  private var subjectItems: [GlassRakuenMoreItem] {
    [
      GlassRakuenMoreItem(
        title: "热门讨论", icon: "flame", requiresLogin: false,
        destination: .rakuenSubjectTopics(.trending)),
      GlassRakuenMoreItem(
        title: "最新讨论", icon: "clock", requiresLogin: false,
        destination: .rakuenSubjectTopics(.latest)),
    ]
  }

  private var groupTopicItems: [GlassRakuenMoreItem] {
    [
      GlassRakuenMoreItem(
        title: "全部话题", icon: "bubble.left.and.bubble.right", requiresLogin: false,
        destination: .rakuenGroupTopics(.all)),
      GlassRakuenMoreItem(
        title: "我参加的", icon: "person.2", requiresLogin: true,
        destination: .rakuenGroupTopics(.joined)),
      GlassRakuenMoreItem(
        title: "我发表的", icon: "square.and.pencil", requiresLogin: true,
        destination: .rakuenGroupTopics(.created)),
      GlassRakuenMoreItem(
        title: "我回复的", icon: "arrowshape.turn.up.left", requiresLogin: true,
        destination: .rakuenGroupTopics(.replied)),
    ]
  }

  private var groupItems: [GlassRakuenMoreItem] {
    [
      GlassRakuenMoreItem(
        title: "全部小组", icon: "square.grid.2x2", requiresLogin: false,
        destination: .groupList(.all)),
      GlassRakuenMoreItem(
        title: "我参加的小组", icon: "star", requiresLogin: true,
        destination: .groupList(.joined)),
      GlassRakuenMoreItem(
        title: "我管理的小组", icon: "checkmark.shield", requiresLogin: true,
        destination: .groupList(.managed)),
    ]
  }

  var body: some View {
    SheetView(title: "更多", size: .both) {
      ScrollView {
        VStack(alignment: .leading, spacing: 14) {
          section("条目讨论", items: subjectItems)
          section("小组话题", items: groupTopicItems)
          section("浏览小组", items: groupItems)
        }
        .padding(.horizontal, theme.metrics.screenPadding)
        .padding(.top, 4)
        .padding(.bottom, 26)
      }
    }
  }

  @ViewBuilder
  private func section(_ title: String, items: [GlassRakuenMoreItem]) -> some View {
    let visible = items.filter { isAuthenticated || !$0.requiresLogin }
    if !visible.isEmpty {
      VStack(alignment: .leading, spacing: 8) {
        Text(title)
          .font(.caption2.weight(.bold).monospaced())
          .foregroundStyle(theme.tertiaryText)
          .padding(.horizontal, 4)
        CardView(padding: 0, role: .strong) {
          VStack(spacing: 0) {
            ForEach(Array(visible.enumerated()), id: \.element.id) { index, item in
              itemRow(item)
              if index < visible.count - 1 {
                Rectangle()
                  .fill(theme.separator)
                  .frame(height: 1)
                  .padding(.leading, 42)
              }
            }
          }
        }
      }
    }
  }

  private func itemRow(_ item: GlassRakuenMoreItem) -> some View {
    Button {
      onSelect(item.destination)
    } label: {
      HStack(spacing: 11) {
        Image(systemName: item.icon)
          .font(.callout)
          .foregroundStyle(theme.accent)
          .frame(width: 20)
        Text(item.title)
          .font(.subheadline.weight(.semibold))
          .foregroundStyle(theme.cardTitle)
        Spacer(minLength: 0)
        if item.requiresLogin {
          Text("需登录")
            .font(.caption2)
            .foregroundStyle(theme.tertiaryText)
        }
        Image(systemName: "chevron.right")
          .font(.caption.weight(.semibold))
          .foregroundStyle(theme.placeholder)
      }
      .padding(.horizontal, 15)
      .padding(.vertical, 13)
      .contentShape(Rectangle())
    }
    .buttonStyle(.plain)
  }
}
