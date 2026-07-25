import SwiftUI

private enum PostReactionPickerLayout {
  static let maxColumnCount = 4
  static let itemLength: CGFloat = 42
  static let spacing: CGFloat = 8
  static let contentPadding: CGFloat = 8
  static let titleHeight: CGFloat = 24

  static func columnCount(for valueCount: Int) -> Int {
    min(max(valueCount, 1), maxColumnCount)
  }

  static func size(for valueCount: Int) -> CGSize {
    let columnCount = columnCount(for: valueCount)
    let rowCount =
      valueCount == 0
      ? 0
      : (valueCount + columnCount - 1) / columnCount

    return CGSize(
      width: contentPadding * 2
        + CGFloat(columnCount) * itemLength
        + CGFloat(max(0, columnCount - 1)) * spacing,
      height: contentPadding * 2
        + titleHeight
        + spacing
        + CGFloat(rowCount) * itemLength
        + CGFloat(max(0, rowCount - 1)) * spacing
    )
  }
}

private enum PostMoreMenuLayout {
  static let width: CGFloat = 148
  static let itemHeight: CGFloat = 44

  static var spacing: CGFloat {
    if #available(iOS 26.0, *) {
      0
    } else {
      4
    }
  }

  static func height(for itemCount: Int) -> CGFloat {
    CGFloat(itemCount) * itemHeight
      + CGFloat(max(0, itemCount - 1)) * spacing
  }
}

private struct PostFloatingSurfaceModifier<Surface: Shape>: ViewModifier {
  @Environment(\.colorScheme) private var colorScheme

  let surface: Surface
  let shadowRadius: CGFloat
  let shadowY: CGFloat

  func body(content: Content) -> some View {
    content
      .background(
        Color(
          uiColor: colorScheme == .dark
            ? .secondarySystemBackground
            : .systemBackground
        ),
        in: surface
      )
      .shadow(
        color: colorScheme == .dark
          ? Color.white.opacity(0.16)
          : Color.black.opacity(0.08),
        radius: colorScheme == .dark ? 2 : 1
      )
      .shadow(
        color: Color.black.opacity(colorScheme == .dark ? 0.6 : 0.2),
        radius: shadowRadius,
        y: shadowY
      )
  }
}

extension View {
  fileprivate func postFloatingSurface<Surface: Shape>(
    _ surface: Surface,
    shadowRadius: CGFloat,
    shadowY: CGFloat
  ) -> some View {
    modifier(
      PostFloatingSurfaceModifier(
        surface: surface,
        shadowRadius: shadowRadius,
        shadowY: shadowY
      )
    )
  }

  @ViewBuilder
  fileprivate func adaptivePostFloatingSurface<Surface: Shape>(
    _ surface: Surface,
    shadowRadius: CGFloat,
    shadowY: CGFloat
  ) -> some View {
    if #available(iOS 26.0, *) {
      self.glassEffect(.regular, in: surface)
    } else {
      self.postFloatingSurface(
        surface,
        shadowRadius: shadowRadius,
        shadowY: shadowY
      )
    }
  }
}

enum PostActionOverlay<Target: Identifiable>: Identifiable {
  case reactions(Target, [Int], anchorY: Double)
  case more(Target, canEdit: Bool, canDelete: Bool, anchorY: Double)

  var id: String {
    switch self {
    case .reactions(let target, _, _):
      return "reactions-\(target.id)"
    case .more(let target, _, _, _):
      return "more-\(target.id)"
    }
  }

  var anchorY: Double {
    switch self {
    case .reactions(_, _, let anchorY), .more(_, _, _, let anchorY):
      return min(max(anchorY, 0), 1)
    }
  }

  var estimatedHeight: CGFloat {
    switch self {
    case .reactions(_, let values, _):
      return PostReactionPickerLayout.size(for: values.count).height
    case .more(_, let canEdit, let canDelete, _):
      let itemCount = (canEdit ? 1 : 0) + (canDelete ? 1 : 0) + 2
      return PostMoreMenuLayout.height(for: itemCount)
    }
  }

  var estimatedWidth: CGFloat {
    switch self {
    case .reactions(_, let values, _):
      return PostReactionPickerLayout.size(for: values.count).width
    case .more:
      return PostMoreMenuLayout.width
    }
  }
}

enum PostMenuAction {
  case edit
  case delete
  case report
  case share
}

struct PostActionOverlayPresenter<Target: Identifiable>: View {
  @Binding var request: PostActionOverlay<Target>?

  let canReport: Bool
  let onReaction: (Target, Int) -> Void
  let onMenuAction: (PostMenuAction, Target) -> Void

  @State private var controlsVisible = false
  @State private var isDismissing = false

  var body: some View {
    GeometryReader { proxy in
      ZStack {
        if let request {
          Color.black.opacity(0.001)
            .ignoresSafeArea()
            .contentShape(Rectangle())
            .onTapGesture {
              dismiss()
            }
            .transition(.opacity)

          PostActionCluster(
            request: request,
            canReport: canReport,
            isVisible: controlsVisible,
            onReaction: { target, value in
              onReaction(target, value)
              dismiss()
            },
            onMenuAction: { action, target in
              dismiss {
                onMenuAction(action, target)
              }
            }
          )
          .id(request.id)
          .position(
            x: proxy.size.width - request.estimatedWidth / 2 - 12,
            y: verticalPosition(for: request, in: proxy.size.height)
          )
        }
      }
    }
    .onChange(of: request?.id, initial: true) { _, requestID in
      guard requestID != nil else {
        controlsVisible = false
        return
      }
      isDismissing = false
      withAnimation(.snappy(duration: 0.24, extraBounce: 0.06)) {
        controlsVisible = true
      }
    }
  }

  private func verticalPosition(
    for request: PostActionOverlay<Target>,
    in availableHeight: CGFloat
  ) -> CGFloat {
    let halfHeight = request.estimatedHeight / 2
    let requestedPosition = availableHeight * request.anchorY
    let minimumPosition = min(halfHeight + 12, availableHeight / 2)
    let maximumPosition = max(minimumPosition, availableHeight - halfHeight - 12)
    return min(max(requestedPosition, minimumPosition), maximumPosition)
  }

  private func dismiss(after completion: @escaping @MainActor () -> Void = {}) {
    guard !isDismissing else {
      return
    }

    isDismissing = true
    withAnimation(.easeIn(duration: 0.16)) {
      controlsVisible = false
    }
    Task { @MainActor in
      try? await Task.sleep(for: .milliseconds(280))
      withAnimation(.easeOut(duration: 0.12)) {
        request = nil
      }
      isDismissing = false
      completion()
    }
  }
}

private struct PostActionCluster<Target: Identifiable>: View {
  let request: PostActionOverlay<Target>
  let canReport: Bool
  let isVisible: Bool
  let onReaction: (Target, Int) -> Void
  let onMenuAction: (PostMenuAction, Target) -> Void

  var body: some View {
    ZStack {
      switch request {
      case .reactions(let target, let values, _):
        PostReactionPickerPanel(values: values, isVisible: isVisible) { value in
          onReaction(target, value)
        }
      case .more(let target, let canEdit, let canDelete, _):
        PostMoreMenuPanel(
          canEdit: canEdit,
          canDelete: canDelete,
          canReport: canReport,
          isVisible: isVisible
        ) { action in
          onMenuAction(action, target)
        }
      }
    }
  }
}

private struct PostReactionPickerPanel: View {
  let values: [Int]
  let isVisible: Bool
  let onSelect: (Int) -> Void

  private var columns: [GridItem] {
    Array(
      repeating: GridItem(
        .fixed(PostReactionPickerLayout.itemLength),
        spacing: PostReactionPickerLayout.spacing
      ),
      count: PostReactionPickerLayout.columnCount(for: values.count)
    )
  }

  var body: some View {
    VStack(alignment: .center, spacing: PostReactionPickerLayout.spacing) {
      Label("贴贴", systemImage: "heart")
        .font(.caption.weight(.semibold))
        .foregroundStyle(.secondary)
        .padding(.horizontal, 4)
        .frame(height: PostReactionPickerLayout.titleHeight)
        .modifier(PostActionEntranceModifier(isVisible: isVisible, index: 0))

      LazyVGrid(columns: columns, spacing: PostReactionPickerLayout.spacing) {
        ForEach(Array(values.enumerated()), id: \.element) { index, value in
          Button {
            onSelect(value)
          } label: {
            reactionLabel(value)
          }
          .buttonStyle(PostReactionChoiceButtonStyle())
          .frame(
            width: PostReactionPickerLayout.itemLength,
            height: PostReactionPickerLayout.itemLength
          )
          .contentShape(Circle())
          .shadow(color: .black.opacity(0.12), radius: 4, y: 2)
          .modifier(
            PostActionEntranceModifier(
              isVisible: isVisible,
              index: index + 1
            )
          )
        }
      }
    }
    .padding(PostReactionPickerLayout.contentPadding)
    .adaptivePostFloatingSurface(
      RoundedRectangle(cornerRadius: 16, style: .continuous),
      shadowRadius: 16,
      shadowY: 7
    )
    .opacity(isVisible ? 1 : 0)
    .scaleEffect(isVisible ? 1 : 0.96, anchor: .trailing)
    .animation(
      isVisible
        ? .snappy(duration: 0.22, extraBounce: 0.04)
        : .easeIn(duration: 0.16),
      value: isVisible
    )
    .fixedSize()
  }

  @ViewBuilder
  private func reactionLabel(_ value: Int) -> some View {
    let code = REACTIONS[value] ?? "bgm125"
    if let item = BBCodeSmileyCatalog.item(for: code) {
      BBCodeSmileyImageView(item: item, size: 24)
    } else {
      Text("(\(code))")
        .font(.caption2)
        .frame(width: 24, height: 24)
    }
  }
}

private struct PostMoreMenuPanel: View {
  let canEdit: Bool
  let canDelete: Bool
  let canReport: Bool
  let isVisible: Bool
  let onSelect: (PostMenuAction) -> Void

  var body: some View {
    let reportIndex = (canEdit ? 1 : 0) + (canDelete ? 1 : 0)

    VStack(alignment: .trailing, spacing: PostMoreMenuLayout.spacing) {
      if canEdit {
        menuButton(
          "编辑",
          systemImage: "pencil",
          action: .edit,
          index: 0
        )
      }

      if canDelete {
        menuButton(
          "删除",
          systemImage: "trash",
          action: .delete,
          role: .destructive,
          tint: .red,
          index: canEdit ? 1 : 0
        )
      }

      menuButton(
        "报告疑虑",
        systemImage: "exclamationmark.triangle",
        action: .report,
        isEnabled: canReport,
        index: reportIndex
      )
      menuButton(
        "分享",
        systemImage: "square.and.arrow.up",
        action: .share,
        index: reportIndex + 1
      )
    }
    .frame(width: PostMoreMenuLayout.width, alignment: .trailing)
  }

  private func menuButton(
    _ title: String,
    systemImage: String,
    action: PostMenuAction,
    role: ButtonRole? = nil,
    tint: Color = .primary,
    isEnabled: Bool = true,
    index: Int
  ) -> some View {
    Button(role: role) {
      onSelect(action)
    } label: {
      Label {
        Text(title)
          .font(.subheadline)
      } icon: {
        Image(systemName: systemImage)
          .font(.body)
          .frame(width: 20)
      }
      .frame(maxWidth: .infinity, alignment: .leading)
      .foregroundStyle(tint)
    }
    .controlSize(.regular)
    .adaptiveButtonStyle(.bordered)
    .adaptiveFlexibleButtonSizing()
    .frame(height: PostMoreMenuLayout.itemHeight)
    .disabled(!isEnabled)
    .modifier(PostActionEntranceModifier(isVisible: isVisible, index: index))
  }
}

private struct PostActionEntranceModifier: ViewModifier {
  let isVisible: Bool
  let index: Int

  func body(content: Content) -> some View {
    content
      .opacity(isVisible ? 1 : 0)
      .scaleEffect(isVisible ? 1 : 0.84, anchor: .trailing)
      .offset(x: isVisible ? 0 : 24)
      .animation(
        isVisible
          ? .snappy(duration: 0.24, extraBounce: 0.08)
            .delay(Double(index) * 0.015)
          : .easeIn(duration: 0.16)
            .delay(Double(index) * 0.008),
        value: isVisible
      )
  }
}

private struct PostReactionChoiceButtonStyle: ButtonStyle {
  func makeBody(configuration: Configuration) -> some View {
    configuration.label
      .scaleEffect(configuration.isPressed ? 0.88 : 1)
      .opacity(configuration.isPressed ? 0.72 : 1)
      .animation(
        .snappy(duration: 0.14, extraBounce: 0),
        value: configuration.isPressed
      )
  }
}

struct PostReactionUsersSheet: View {
  let reaction: ReactionDTO

  @Environment(\.dismiss) private var dismiss
  @Environment(\.openURL) private var openURL

  var body: some View {
    SheetView(title: "贴贴") {
      List(reaction.users) { user in
        Button {
          dismiss()
          if let url = URL(string: user.link) {
            openURL(url)
          }
        } label: {
          Text(user.nickname)
        }
        .buttonStyle(.plain)
      }
    }
  }
}

func postImageURL(_ rawValue: String?, domains: BangumiDomains) -> String? {
  guard let rawValue, !rawValue.isEmpty else {
    return nil
  }

  let secureValue = rawValue.replacingOccurrences(of: "http://", with: "https://")
  guard var components = URLComponents(string: secureValue),
    components.host == CDN_DOMAIN,
    let imageHost = BangumiDomains.hostAndPort(from: domains.image)
  else {
    return secureValue
  }

  components.host = imageHost.host
  components.port = imageHost.port
  return components.url?.absoluteString ?? secureValue
}
