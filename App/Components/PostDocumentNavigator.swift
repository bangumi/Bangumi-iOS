import SwiftUI

struct PostDocumentNavigationItem: Hashable, Identifiable, Sendable {
  let postID: Int
  let floor: String

  var id: Int {
    postID
  }
}

enum PostDocumentScrollTarget: Equatable, Sendable {
  case top
  case bottom
  case post(Int)
}

struct PostDocumentScrollRequest: Equatable, Identifiable, Sendable {
  let id = UUID()
  let target: PostDocumentScrollTarget
  let animated: Bool
}

struct PostDocumentViewportState: Equatable, Sendable {
  let canScrollToTop: Bool
  let visiblePostID: Int?

  static let top = PostDocumentViewportState(
    canScrollToTop: false,
    visiblePostID: nil
  )
}

struct PostDocumentControlConfiguration {
  let canReply: Bool
  let filterModes: [ReplyFilterMode]
  let filterMode: Binding<ReplyFilterMode>
  let sortOrder: Binding<ReplySortOrder>
}

struct PostDocumentNavigatorOverlay: View {
  let items: [PostDocumentNavigationItem]
  let visiblePostID: Int?
  let controls: PostDocumentControlConfiguration
  let canScrollToTop: Bool
  let onReply: () -> Void
  let onSelect: (PostDocumentScrollTarget) -> Void

  @State private var showsFloorNavigator = false

  @Environment(\.theme) private var theme

  private var visibleItem: PostDocumentNavigationItem? {
    items.first { $0.postID == visiblePostID }
  }

  private var widestFloor: String {
    items.map(\.floor).max { lhs, rhs in
      lhs.count < rhs.count
    } ?? "楼层"
  }

  var body: some View {
    if theme.isClassic {
      controlBar
    } else {
      glassControlBar
    }
  }

  private var glassControlBar: some View {
    HStack(spacing: 10) {
      HStack(spacing: 0) {
        Menu {
          Picker("筛选", selection: controls.filterMode) {
            ForEach(controls.filterModes, id: \.self) { mode in
              Label(mode.description, systemImage: mode.icon).tag(mode)
            }
          }
          Picker("排序", selection: controls.sortOrder) {
            ForEach(ReplySortOrder.allCases, id: \.self) { order in
              Label(order.description, systemImage: order.icon).tag(order)
            }
          }
        } label: {
          glassBarIcon("line.3.horizontal.decrease")
        }
        .tint(.primary)
        .accessibilityLabel("筛选与排序")

        if items.count > 1 {
          glassBarDivider
          Button {
            showsFloorNavigator = true
          } label: {
            HStack(spacing: 5) {
              Image(systemName: "list.number")
              ZStack(alignment: .leading) {
                Text("楼层")
                  .hidden()
                Text(widestFloor)
                  .hidden()
                Text(visibleItem?.floor ?? "楼层")
              }
              .monospacedDigit()
            }
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(.primary)
            .padding(.horizontal, 14)
            .frame(height: 42)
            .contentShape(Rectangle())
          }
          .buttonStyle(.plain)
          .accessibilityHint("选择要跳转的楼层")
          .popover(isPresented: $showsFloorNavigator) {
            PostDocumentFloorNavigator(
              items: items,
              visiblePostID: visiblePostID,
              onSelect: onSelect
            )
            .presentationCompactAdaptation(.sheet)
          }
        }

        glassBarDivider
        Button {
          onSelect(.top)
        } label: {
          glassBarIcon("arrow.up")
        }
        .buttonStyle(.plain)
        .disabled(!canScrollToTop)
        .opacity(canScrollToTop ? 1 : 0.35)
        .accessibilityLabel("回到顶部")
      }
      .glassEffectIfAvailable(shape: Capsule())

      Button(action: onReply) {
        Image(systemName: "plus.bubble.fill")
          .font(.system(size: 17, weight: .semibold))
          .foregroundStyle(.white)
          .frame(width: 44, height: 44)
          .background {
            Circle()
              .fill(
                LinearGradient(
                  colors: theme.ctaGradient,
                  startPoint: .topLeading, endPoint: .bottomTrailing)
              )
              .shadow(
                color: theme.ctaShadow.color,
                radius: theme.ctaShadow.radius, y: theme.ctaShadow.y)
          }
          .contentShape(Circle())
      }
      .buttonStyle(.plain)
      .disabled(!controls.canReply)
      .opacity(controls.canReply ? 1 : 0.4)
      .accessibilityLabel("回复")
    }
  }

  private func glassBarIcon(_ name: String) -> some View {
    Image(systemName: name)
      .font(.system(size: 16, weight: .semibold))
      .foregroundStyle(.primary)
      .frame(width: 44, height: 42)
      .contentShape(Rectangle())
  }

  private var glassBarDivider: some View {
    Rectangle()
      .fill(theme.separator)
      .frame(width: 1, height: 18)
  }

  private var controlBar: some View {
    HStack(spacing: 8) {
      Button(action: onReply) {
        Label("回复", systemImage: "plus.bubble")
          .labelStyle(.iconOnly)
      }
      .adaptiveButtonStyle(.bordered)
      .disabled(!controls.canReply)

      PostDocumentFilterSortControls(configuration: controls)

      if items.count > 1 {
        Button {
          showsFloorNavigator = true
        } label: {
          HStack(spacing: 4) {
            Image(systemName: "list.number")
            ZStack(alignment: .leading) {
              Text("楼层")
                .hidden()
              Text(widestFloor)
                .hidden()
              Text(visibleItem?.floor ?? "楼层")
            }
            .monospacedDigit()
          }
        }
        .adaptiveButtonStyle(.bordered)
        .accessibilityHint("选择要跳转的楼层")
        .popover(isPresented: $showsFloorNavigator) {
          PostDocumentFloorNavigator(
            items: items,
            visiblePostID: visiblePostID,
            onSelect: onSelect
          )
          .presentationCompactAdaptation(.sheet)
        }
      }

      Button {
        onSelect(.top)
      } label: {
        Label("回到顶部", systemImage: "arrow.up")
          .labelStyle(.iconOnly)
      }
      .adaptiveButtonStyle(.borderedProminent)
      .disabled(!canScrollToTop)
    }
  }
}

private struct PostDocumentFilterSortControls: View {
  let filterModes: [ReplyFilterMode]
  @Binding var filterMode: ReplyFilterMode
  @Binding var sortOrder: ReplySortOrder

  init(configuration: PostDocumentControlConfiguration) {
    filterModes = configuration.filterModes
    _filterMode = configuration.filterMode
    _sortOrder = configuration.sortOrder
  }

  var body: some View {
    HStack(spacing: 8) {
      Menu {
        Picker("筛选", selection: $filterMode) {
          ForEach(filterModes, id: \.self) { mode in
            Label(mode.description, systemImage: mode.icon).tag(mode)
          }
        }
      } label: {
        Label("筛选", systemImage: filterMode.icon)
          .labelStyle(.iconOnly)
      }
      .adaptiveButtonStyle(.bordered)
      .accessibilityValue(Text(filterMode.description))

      Menu {
        Picker("排序", selection: $sortOrder) {
          ForEach(ReplySortOrder.allCases, id: \.self) { order in
            Label(order.description, systemImage: order.icon).tag(order)
          }
        }
      } label: {
        Label("排序", systemImage: sortOrder.icon)
          .labelStyle(.iconOnly)
      }
      .adaptiveButtonStyle(.bordered)
      .accessibilityValue(Text(sortOrder.description))
    }
  }
}

private struct PostDocumentFloorNavigator: View {
  let items: [PostDocumentNavigationItem]
  let onSelect: (PostDocumentScrollTarget) -> Void

  @Environment(\.dismiss) private var dismiss
  @State private var selectedIndex: Double

  init(
    items: [PostDocumentNavigationItem],
    visiblePostID: Int?,
    onSelect: @escaping (PostDocumentScrollTarget) -> Void
  ) {
    self.items = items
    self.onSelect = onSelect
    let initialIndex =
      items.firstIndex { $0.postID == visiblePostID }
      ?? 0
    _selectedIndex = State(initialValue: Double(initialIndex))
  }

  private var clampedIndex: Int {
    min(max(Int(selectedIndex.rounded()), 0), items.count - 1)
  }

  private var selectedItem: PostDocumentNavigationItem {
    items[clampedIndex]
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 20) {
      HStack {
        Text("楼层电梯")
          .font(.headline)

        Spacer()

        Text(selectedItem.floor)
          .font(.headline)
          .monospacedDigit()

        Button {
          dismiss()
        } label: {
          Label("完成", systemImage: "xmark")
            .labelStyle(.iconOnly)
        }
        .buttonStyle(.bordered)
      }

      Slider(
        value: $selectedIndex,
        in: 0...Double(items.count - 1),
        step: 1,
        label: {
          Text("楼层")
        },
        minimumValueLabel: {
          Text(items[0].floor)
            .font(.caption)
            .monospacedDigit()
        },
        maximumValueLabel: {
          Text(items[items.count - 1].floor)
            .font(.caption)
            .monospacedDigit()
        },
        onEditingChanged: { isEditing in
          if !isEditing {
            selectCurrentItem()
          }
        }
      )
      .accessibilityValue(Text(selectedItem.floor))

      HStack {
        Button {
          select(index: clampedIndex - 1)
        } label: {
          Label("上一层", systemImage: "chevron.up")
            .labelStyle(.iconOnly)
        }
        .disabled(clampedIndex == 0)

        Spacer()

        Button {
          selectTop()
        } label: {
          Label("回到顶部", systemImage: "arrow.up.to.line")
            .labelStyle(.iconOnly)
        }

        Button {
          selectBottom()
        } label: {
          Label("跳到底部", systemImage: "arrow.down.to.line")
            .labelStyle(.iconOnly)
        }

        Spacer()

        Button {
          select(index: clampedIndex + 1)
        } label: {
          Label("下一层", systemImage: "chevron.down")
            .labelStyle(.iconOnly)
        }
        .disabled(clampedIndex == items.count - 1)
      }
      .buttonStyle(.bordered)
      .controlSize(.large)
    }
    .padding()
    .presentationDetents([.medium])
    .presentationDragIndicator(.visible)
  }

  private func select(index: Int) {
    let index = min(max(index, 0), items.count - 1)
    selectedIndex = Double(index)
    onSelect(.post(items[index].postID))
  }

  private func selectTop() {
    selectedIndex = 0
    onSelect(.top)
  }

  private func selectBottom() {
    selectedIndex = Double(items.count - 1)
    onSelect(.bottom)
  }

  private func selectCurrentItem() {
    onSelect(.post(selectedItem.postID))
  }
}
