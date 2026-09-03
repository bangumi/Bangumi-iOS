import Flow
import SwiftUI

struct GlassTypeChips: View {
  @Binding var selection: SubjectType
  let counts: [SubjectType: Int]

  @Environment(\.theme) private var theme

  init(selection: Binding<SubjectType>, counts: [SubjectType: Int]) {
    self._selection = selection
    self.counts = counts
  }

  var body: some View {
    ScrollView(.horizontal, showsIndicators: false) {
      HStack(spacing: 7) {
        ForEach(SubjectType.progressTypes) { type in
          GlassChip(
            title: type.description,
            count: counts[type, default: 0],
            isSelected: selection == type
          ) {
            withAnimation(.spring(response: 0.28, dampingFraction: 0.86)) {
              selection = type
            }
          }
        }
      }
      .padding(.horizontal, theme.metrics.screenPadding)
      .padding(.vertical, 2)
    }
    .scrollClipDisabled()
  }
}

enum GlassFillKind {
  case accent
  case muted
  case complete
  case glass
  case cancel
}

struct GlassFillButton<Content: View>: View {
  let kind: GlassFillKind
  @ViewBuilder var content: Content

  @Environment(\.theme) private var theme

  private var shape: RoundedRectangle {
    RoundedRectangle(cornerRadius: theme.metrics.controlRadius, style: .continuous)
  }

  var body: some View {
    content
      .font(.subheadline.weight(.bold))
      .frame(maxWidth: .infinity)
      .padding(.vertical, 9)
      .foregroundStyle(foreground)
      .background(fill, in: shape)
      .overlay {
        if let border {
          shape.strokeBorder(border, lineWidth: 1)
        }
      }
      .shadow(color: shadow.color, radius: shadow.radius, y: shadow.y)
  }

  private var foreground: Color {
    switch kind {
    case .accent:
      .white
    case .muted:
      theme.tertiaryText
    case .complete:
      theme.successText
    case .glass:
      theme.body
    case .cancel:
      theme.danger
    }
  }

  private var fill: AnyShapeStyle {
    switch kind {
    case .accent:
      AnyShapeStyle(
        LinearGradient(
          colors: theme.ctaGradient, startPoint: .topLeading, endPoint: .bottomTrailing))
    case .muted:
      AnyShapeStyle(theme.controlFill)
    case .complete:
      AnyShapeStyle(theme.success.opacity(0.14))
    case .glass:
      AnyShapeStyle(theme.controlFill)
    case .cancel:
      AnyShapeStyle(theme.danger.opacity(0.12))
    }
  }

  private var border: Color? {
    switch kind {
    case .accent, .muted:
      nil
    case .complete:
      theme.success.opacity(0.3)
    case .glass:
      theme.controlBorder
    case .cancel:
      theme.danger.opacity(0.28)
    }
  }

  private var shadow: ThemeShadow {
    kind == .accent ? theme.ctaShadow : ThemeShadow(color: .clear, radius: 0, y: 0)
  }
}

struct GlassGhostIconButton: View {
  let systemImage: String
  let action: () -> Void

  @Environment(\.theme) private var theme

  init(systemImage: String, action: @escaping () -> Void) {
    self.systemImage = systemImage
    self.action = action
  }

  private var shape: RoundedRectangle {
    RoundedRectangle(cornerRadius: theme.metrics.controlRadius, style: .continuous)
  }

  var body: some View {
    Button(action: action) {
      Image(systemName: systemImage)
        .font(.subheadline.weight(.semibold))
        .foregroundStyle(theme.secondaryText)
        .frame(width: 38, height: 38)
        .background(theme.controlFill, in: shape)
        .overlay {
          shape.strokeBorder(theme.controlBorder, lineWidth: 1)
        }
        .contentShape(shape)
    }
    .buttonStyle(.plain)
  }
}

struct GlassSyncBanner: View {
  let progress: Double
  let current: Int?
  let total: Int?

  @Environment(\.theme) private var theme

  init(progress: Double, current: Int? = nil, total: Int? = nil) {
    self.progress = progress
    self.current = current
    self.total = total
  }

  var body: some View {
    CardView(padding: theme.metrics.cardPadding) {
      VStack(alignment: .leading, spacing: 12) {
        HStack(spacing: 10) {
          ProgressView()
            .controlSize(.small)
            .tint(theme.accent)
          Text("正在同步收藏")
            .font(.subheadline.weight(.bold))
            .foregroundStyle(theme.cardTitle)
          Spacer(minLength: 0)
          if let current, let total, total > 0 {
            counter(current: current, total: total)
          }
        }
        bar
        Text("首次同步需要完整下载收藏，之后只做增量更新")
          .font(.caption)
          .foregroundStyle(theme.tertiaryText)
      }
      .frame(maxWidth: .infinity, alignment: .leading)
    }
  }

  private func counter(current: Int, total: Int) -> some View {
    HStack(spacing: 0) {
      Text("\(current)")
        .foregroundStyle(theme.accentDeep)
      Text("/\(total)")
        .foregroundStyle(theme.tertiaryText)
    }
    .font(.system(size: 13, weight: .bold, design: .monospaced))
  }

  private var bar: some View {
    GeometryReader { geo in
      ZStack(alignment: .leading) {
        Capsule()
          .fill(theme.track)
        Capsule()
          .fill(
            LinearGradient(
              colors: theme.ctaGradient, startPoint: .leading, endPoint: .trailing)
          )
          .frame(width: geo.size.width * min(max(progress, 0), 1))
      }
    }
    .frame(height: 7)
  }
}

struct GlassSkeletonCard: View {
  var opacity: Double = 1

  @Environment(\.theme) private var theme

  init(opacity: Double = 1) {
    self.opacity = opacity
  }

  var body: some View {
    CardView(padding: theme.metrics.cardPadding) {
      HStack(alignment: .top, spacing: 12) {
        RoundedRectangle(cornerRadius: theme.metrics.cellRadius, style: .continuous)
          .fill(theme.track)
          .frame(width: 62, height: 87)
        VStack(alignment: .leading, spacing: 9) {
          Capsule()
            .fill(theme.track)
            .frame(width: 160, height: 13)
          Capsule()
            .fill(theme.separator)
            .frame(width: 100, height: 11)
          HStack(spacing: 6) {
            ForEach(0..<3, id: \.self) { _ in
              RoundedRectangle(cornerRadius: theme.metrics.cellRadius, style: .continuous)
                .fill(theme.separator)
                .frame(width: 34, height: 34)
            }
          }
          .padding(.top, 7)
        }
        .padding(.top, 6)
        Spacer(minLength: 0)
      }
    }
    .opacity(opacity)
  }
}

struct GlassEmptyCard: View {
  let systemImage: String
  let title: String
  let description: String

  init(systemImage: String, title: String, description: String) {
    self.systemImage = systemImage
    self.title = title
    self.description = description
  }

  var body: some View {
    ThemedEmptyState(systemImage: systemImage, title: title, description: description)
  }
}

struct GlassSegmented<Value: Hashable, Label: View>: View {
  @Binding var selection: Value
  let items: [Value]
  let label: (Value) -> Label

  @Environment(\.theme) private var theme

  init(
    selection: Binding<Value>, items: [Value],
    @ViewBuilder label: @escaping (Value) -> Label
  ) {
    self._selection = selection
    self.items = items
    self.label = label
  }

  private var trackShape: RoundedRectangle {
    RoundedRectangle(cornerRadius: theme.metrics.controlRadius, style: .continuous)
  }

  private var itemShape: RoundedRectangle {
    RoundedRectangle(cornerRadius: theme.metrics.controlRadius - 4, style: .continuous)
  }

  var body: some View {
    HStack(spacing: 6) {
      ForEach(items, id: \.self) { item in
        segment(item)
      }
    }
    .padding(4)
    .frame(height: GlassForm.controlHeight)
    .background {
      trackShape
        .fill(theme.controlFill)
        .overlay {
          trackShape.strokeBorder(theme.controlBorder, lineWidth: 1)
        }
    }
  }

  private func segment(_ item: Value) -> some View {
    let selected = selection == item
    return Button {
      withAnimation(.spring(response: 0.28, dampingFraction: 0.86)) {
        selection = item
      }
    } label: {
      label(item)
        .labelStyle(.titleAndIcon)
        .font(.footnote.weight(selected ? .heavy : .semibold))
        .foregroundStyle(selected ? Color.white : theme.secondaryText)
        .lineLimit(1)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background {
          if selected {
            itemShape
              .fill(
                LinearGradient(
                  colors: theme.ctaGradient,
                  startPoint: .topLeading, endPoint: .bottomTrailing)
              )
              .shadow(
                color: theme.chipShadow.color,
                radius: theme.chipShadow.radius, y: theme.chipShadow.y)
          }
        }
        .contentShape(itemShape)
    }
    .buttonStyle(.plain)
  }
}

struct GlassOptionsSheet: View {
  @Binding var viewMode: ProgressViewMode
  @Binding var sortMode: ProgressSortMode
  @Binding var secondLineMode: ProgressSecondLineMode
  let onRefreshAll: () -> Void

  @Environment(\.dismiss) private var dismiss
  @Environment(\.theme) private var theme

  init(
    viewMode: Binding<ProgressViewMode>,
    sortMode: Binding<ProgressSortMode>,
    secondLineMode: Binding<ProgressSecondLineMode>,
    onRefreshAll: @escaping () -> Void
  ) {
    self._viewMode = viewMode
    self._sortMode = sortMode
    self._secondLineMode = secondLineMode
    self.onRefreshAll = onRefreshAll
  }

  var body: some View {
    ScrollView(showsIndicators: false) {
      VStack(alignment: .leading, spacing: GlassForm.blockSpacing) {
        GlassFormSection(title: "显示模式") {
          GlassSegmented(selection: $viewMode, items: ProgressViewMode.allCases) { mode in
            Label(mode.desc, systemImage: mode.icon)
          }
        }
        GlassFormSection(title: "排序方式") {
          GlassSegmented(selection: $sortMode, items: ProgressSortMode.allCases) { mode in
            Text(mode.desc)
          }
        }
        GlassFormSection(title: "副标题内容") {
          HFlow(spacing: 7) {
            ForEach(ProgressSecondLineMode.allCases, id: \.self) { mode in
              GlassChip(title: mode.desc, isSelected: secondLineMode == mode) {
                withAnimation(.easeInOut(duration: 0.18)) {
                  secondLineMode = mode
                }
              }
            }
          }
        }
        refreshRow
      }
      .padding(.horizontal, theme.metrics.screenPadding)
      .padding(.top, 28)
      .padding(.bottom, theme.metrics.screenPadding)
    }
    .presentationDetents([.height(420)])
    .presentationDragIndicator(.visible)
  }

  private var refreshRow: some View {
    let shape = RoundedRectangle(cornerRadius: theme.metrics.controlRadius, style: .continuous)
    return Button {
      dismiss()
      onRefreshAll()
    } label: {
      HStack(spacing: 10) {
        Image(systemName: "arrow.triangle.2.circlepath")
        Text("刷新所有收藏")
          .font(.subheadline.weight(.bold))
        Spacer(minLength: 0)
        Image(systemName: "chevron.right")
          .font(.footnote.weight(.semibold))
          .foregroundStyle(theme.disabled)
      }
      .foregroundStyle(theme.onTintText)
      .padding(.horizontal, 14)
      .frame(height: GlassForm.controlHeight)
      .background {
        shape
          .fill(theme.tint)
          .overlay {
            shape.strokeBorder(theme.accent.opacity(0.18), lineWidth: 1)
          }
      }
      .contentShape(shape)
    }
    .buttonStyle(.plain)
  }
}
