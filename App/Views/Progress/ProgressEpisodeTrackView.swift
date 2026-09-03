import SwiftUI

enum ProgressEpisodeTickKind {
  case watched
  case aired
  case unaired
  case dropped
  case wish
  case next

  init(episode: EpisodeDTO, isNext: Bool) {
    switch episode.collectionTypeEnum {
    case .collect:
      self = .watched
    case .dropped:
      self = .dropped
    case .wish:
      self = .wish
    case .none:
      if isNext {
        self = episode.aired ? .next : .unaired
      } else {
        self = episode.aired ? .aired : .unaired
      }
    }
  }

  var cellState: EpisodeCellState {
    switch self {
    case .watched:
      .watched
    case .aired:
      .aired
    case .unaired:
      .unaired
    case .dropped:
      .dropped
    case .wish:
      .wish
    case .next:
      .next
    }
  }
}

struct ProgressTickScrubState: Equatable {
  enum Phase: Equatable {
    case preview
    case cancel
  }

  var phase: Phase
  var target: EpisodeDTO
  var restore: EpisodeDTO
  var canCommit: Bool
}

struct ProgressEpisodeTrackView: View {
  let episodes: [EpisodeDTO]
  let totalEpisodes: Int
  let interactionMode: EpisodeGridInteractionMode
  let subjectCollectionType: CollectionType
  var reload: (() async -> Void)? = nil
  var onScrubChange: ((ProgressTickScrubState?) -> Void)? = nil
  var onScrubCommit: ((EpisodeDTO) -> Void)? = nil

  private var usesSquares: Bool {
    let total = totalEpisodes > 0 ? totalEpisodes : episodes.count
    return total <= 6
  }

  var body: some View {
    if usesSquares {
      ProgressEpisodeSquaresView(
        episodes: episodes,
        interactionMode: interactionMode,
        subjectCollectionType: subjectCollectionType,
        reload: reload
      )
    } else {
      ProgressEpisodeTicksView(
        episodes: episodes,
        totalEpisodes: totalEpisodes,
        onScrubChange: onScrubChange,
        onScrubCommit: onScrubCommit
      )
    }
  }
}

struct ProgressEpisodeSquaresView: View {
  let episodes: [EpisodeDTO]
  let interactionMode: EpisodeGridInteractionMode
  let subjectCollectionType: CollectionType
  var reload: (() async -> Void)? = nil

  @Environment(\.theme) private var theme

  private var nextId: Int? {
    episodes.first(where: { $0.collectionTypeEnum == .none })?.id
  }

  var body: some View {
    HStack(spacing: 6) {
      ForEach(episodes) { episode in
        ProgressEpisodeChip(
          episode: episode,
          kind: ProgressEpisodeTickKind(episode: episode, isNext: episode.id == nextId),
          size: 34,
          cornerRadius: theme.metrics.cellRadius,
          interactionMode: interactionMode,
          subjectCollectionType: subjectCollectionType,
          reload: reload
        )
      }
      Spacer(minLength: 0)
    }
  }
}

@MainActor
private final class GearHaptic {
  private let selection = UISelectionFeedbackGenerator()
  private var lastID: Int?

  func prepare() {
    lastID = nil
    selection.prepare()
  }

  func play(_ id: Int) {
    guard id != lastID else { return }
    lastID = id
    selection.selectionChanged()
    selection.prepare()
  }
}

private enum ProgressTickMetrics {
  static let maxVisible = 24
  static let gap: CGFloat = 2
  static let idleHeight: CGFloat = 12
  static let currentHeight: CGFloat = 16
  static let lensOuter: CGFloat = 13
  static let lensNear: CGFloat = 15
  static let lensFocus: CGFloat = 22
  static let reservedHeight: CGFloat = 22
  static let cancelEnter: CGFloat = 32
  static let cancelExit: CGFloat = 20
  static let edgeHot: CGFloat = 26
}

struct ProgressEpisodeTicksView: View {
  let episodes: [EpisodeDTO]
  let totalEpisodes: Int
  var onScrubChange: ((ProgressTickScrubState?) -> Void)? = nil
  var onScrubCommit: ((EpisodeDTO) -> Void)? = nil

  @AppStorage("titlePreference") var titlePreference: TitlePreference = .original
  @Environment(\.theme) private var theme

  @State private var barWidth: CGFloat = 0
  @State private var windowStart: Int = 0
  @State private var scrubIndex: Int?
  @State private var isDragging = false
  @State private var isCancelling = false
  @State private var fingerX: CGFloat = 0
  @State private var lift: CGFloat = 0
  @State private var bubbleHeight: CGFloat = 0
  @State private var edgeHoldTask: Task<Void, Never>?
  @State private var edgeHoldDirection: Int = 0
  @State private var gearHaptic = GearHaptic()

  private var currentIndex: Int {
    episodes.lastIndex(where: { $0.collectionTypeEnum == .collect }) ?? 0
  }

  private var playheadIndex: Int {
    min(max(scrubIndex ?? currentIndex, 0), max(episodes.count - 1, 0))
  }

  private var currentEpisode: EpisodeDTO? {
    episodes.indices.contains(currentIndex) ? episodes[currentIndex] : nil
  }

  private var playheadEpisode: EpisodeDTO? {
    episodes.indices.contains(playheadIndex) ? episodes[playheadIndex] : currentEpisode
  }

  private var visibleCount: Int {
    min(ProgressTickMetrics.maxVisible, episodes.count)
  }

  private var visibleEpisodes: ArraySlice<EpisodeDTO> {
    guard !episodes.isEmpty else { return [] }
    let start = min(max(windowStart, 0), max(episodes.count - visibleCount, 0))
    return episodes[start..<(start + visibleCount)]
  }

  private var magnifying: Bool {
    isDragging && !isCancelling
  }

  var body: some View {
    VStack(spacing: 5) {
      tickBar
        .overlay(alignment: .top) {
          bubbleOverlay
        }
        .zIndex(isDragging ? 2 : 0)

      HStack {
        Text(leadingCaption)
        Spacer(minLength: 0)
        Text(trailingCaption)
      }
      .font(.system(size: 10, weight: .semibold, design: .monospaced))
      .foregroundStyle(theme.tertiaryText)
      .overlay {
        playheadCaption
      }
    }
    .onAppear {
      recenterWindow()
      gearHaptic.prepare()
    }
    .onChange(of: episodes.map(\.id)) { _, _ in
      resetScrub()
      recenterWindow()
    }
    .onDisappear {
      stopEdgeHold()
    }
  }

  private var tickBar: some View {
    HStack(alignment: .bottom, spacing: ProgressTickMetrics.gap) {
      ForEach(Array(visibleEpisodes.enumerated()), id: \.element.id) { offset, episode in
        let index = windowStart + offset
        tick(episode, index: index, offset: offset)
      }
    }
    .frame(height: ProgressTickMetrics.reservedHeight, alignment: .bottom)
    .background {
      GeometryReader { geo in
        Color.clear
          .onAppear { barWidth = geo.size.width }
          .onChange(of: geo.size.width) { _, width in
            barWidth = width
          }
      }
    }
    .overlay {
      if magnifying {
        edgeGlow
      }
    }
    .contentShape(Rectangle())
    .gesture(scrubGesture)
  }

  @ViewBuilder
  private var bubbleOverlay: some View {
    if isDragging, let episode = playheadEpisode, let restore = currentEpisode {
      let dashHeight = isCancelling ? max(10, min(lift - 8, 22)) : 0
      VStack(spacing: 0) {
        ProgressTickBubble(
          title: isCancelling ? "松开取消" : "EP.\(episode.sort.episodeDisplay)",
          subtitle: isCancelling
            ? "回到 EP.\(restore.sort.episodeDisplay)"
            : episode.tickAirCaption,
          detail: isCancelling
            ? nil
            : titlePreference.title(name: episode.name, nameCN: episode.nameCN),
          systemImage: isCancelling ? "arrow.uturn.backward" : nil,
          isCancelling: isCancelling,
          showsArrow: !isCancelling
        )
        if isCancelling {
          Canvas { context, size in
            var path = Path()
            path.move(to: CGPoint(x: size.width / 2, y: 0))
            path.addLine(to: CGPoint(x: size.width / 2, y: size.height))
            context.stroke(
              path,
              with: .color(theme.danger.opacity(0.5)),
              style: StrokeStyle(lineWidth: 1.5, dash: [3, 3])
            )
          }
          .frame(width: 2, height: dashHeight)
        }
      }
      .onGeometryChange(for: CGFloat.self) { proxy in
        proxy.size.height
      } action: { height in
        bubbleHeight = height
      }
      .offset(x: bubbleX, y: bubbleY)
      .allowsHitTesting(false)
      .transition(
        .scale(scale: 0.72, anchor: .bottom)
          .combined(with: .opacity)
      )
    }
  }

  @ViewBuilder
  private var edgeGlow: some View {
    let leading = fingerX < ProgressTickMetrics.edgeHot && windowStart > 0
    let trailing =
      fingerX > barWidth - ProgressTickMetrics.edgeHot
      && windowStart + visibleCount < episodes.count
    ZStack {
      if leading {
        LinearGradient(
          colors: [theme.accent.opacity(0.28), .clear],
          startPoint: .leading,
          endPoint: .trailing
        )
        .frame(width: ProgressTickMetrics.edgeHot)
        .frame(maxWidth: .infinity, alignment: .leading)
      }
      if trailing {
        LinearGradient(
          colors: [.clear, theme.accent.opacity(0.28)],
          startPoint: .leading,
          endPoint: .trailing
        )
        .frame(width: ProgressTickMetrics.edgeHot)
        .frame(maxWidth: .infinity, alignment: .trailing)
      }
    }
    .padding(.vertical, -4)
    .allowsHitTesting(false)
  }

  private var scrubGesture: some Gesture {
    LongPressGesture(minimumDuration: 0.3)
      .sequenced(
        before: DragGesture(minimumDistance: 0, coordinateSpace: .local)
      )
      .onChanged { value in
        switch value {
        case .first(true):
          armScrub()
        case .second(true, let drag):
          armScrub()
          if let drag {
            handleDrag(drag)
          }
        default:
          break
        }
      }
      .onEnded { _ in
        finishScrub()
      }
  }

  private func armScrub() {
    guard !isDragging else { return }
    withAnimation(.spring(response: 0.32, dampingFraction: 0.72)) {
      isDragging = true
      isCancelling = false
      lift = 0
    }
    if scrubIndex == nil {
      scrubIndex = currentIndex
    }
    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    gearHaptic.prepare()
    reportScrub()
  }

  private func handleDrag(_ drag: DragGesture.Value) {
    fingerX = min(max(0, drag.location.x), max(barWidth, 1))
    lift = max(0, -drag.translation.height)

    let wasCancelling = isCancelling
    let nowCancelling =
      isCancelling
      ? lift > ProgressTickMetrics.cancelExit
      : lift > ProgressTickMetrics.cancelEnter
    if nowCancelling != wasCancelling {
      withAnimation(.spring(response: 0.22, dampingFraction: 0.78)) {
        isCancelling = nowCancelling
      }
      if nowCancelling {
        UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
        stopEdgeHold()
      } else {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
      }
    }

    if isCancelling {
      reportScrub()
      return
    }

    let leadingHot = fingerX < ProgressTickMetrics.edgeHot && windowStart > 0
    let trailingHot =
      fingerX > barWidth - ProgressTickMetrics.edgeHot
      && windowStart + visibleCount < episodes.count
    if trailingHot && playheadIndex >= windowStart + visibleCount - 1 {
      startEdgeHold(+1)
    } else if leadingHot && playheadIndex <= windowStart {
      startEdgeHold(-1)
    } else {
      stopEdgeHold()
      movePlayhead(to: fingerX)
    }
    reportScrub()
  }

  private func movePlayhead(to x: CGFloat) {
    guard barWidth > 0, visibleCount > 0 else { return }
    let clampedX = min(max(0, x), barWidth)
    let offset = min(
      Int((clampedX / barWidth) * CGFloat(visibleCount)),
      visibleCount - 1
    )
    let index = windowStart + offset
    applyPlayhead(index)
  }

  private func applyPlayhead(_ index: Int) {
    let clamped = min(max(index, 0), max(episodes.count - 1, 0))
    if scrubIndex != clamped {
      withAnimation(.snappy(duration: 0.16)) {
        scrubIndex = clamped
      }
      if let episode = playheadEpisode {
        gearHaptic.play(episode.id)
      }
    } else if edgeHoldDirection != 0, clamped == 0 || clamped == episodes.count - 1 {
      stopEdgeHold()
    }
    clampWindow(to: clamped)
  }

  private func startEdgeHold(_ direction: Int) {
    guard edgeHoldDirection != direction else { return }
    stopEdgeHold()
    edgeHoldDirection = direction
    let startedAt = Date()
    edgeHoldTask = Task { @MainActor in
      while !Task.isCancelled {
        let elapsed = Date().timeIntervalSince(startedAt)
        let rate: Double
        if elapsed > 1.5 {
          rate = 48
        } else if elapsed > 0.5 {
          rate = 12
        } else {
          rate = 6
        }
        let delay = UInt64(1_000_000_000 / rate)
        try? await Task.sleep(nanoseconds: delay)
        guard !Task.isCancelled else { return }
        applyPlayhead(playheadIndex + direction)
        reportScrub()
      }
    }
  }

  private func stopEdgeHold() {
    edgeHoldTask?.cancel()
    edgeHoldTask = nil
    edgeHoldDirection = 0
  }

  private func finishScrub() {
    stopEdgeHold()
    let target = playheadEpisode
    let canCommit = target?.aired == true && !isCancelling
    let shouldCommit = isDragging && canCommit
    withAnimation(.spring(response: 0.28, dampingFraction: 0.78)) {
      isDragging = false
      isCancelling = false
      lift = 0
      if !shouldCommit {
        scrubIndex = nil
      }
    }
    if shouldCommit, let target {
      onScrubCommit?(target)
    }
    onScrubChange?(nil)
    gearHaptic.prepare()
  }

  private func resetScrub() {
    stopEdgeHold()
    scrubIndex = nil
    isDragging = false
    isCancelling = false
    lift = 0
    onScrubChange?(nil)
    gearHaptic.prepare()
  }

  private func reportScrub() {
    guard isDragging, let target = playheadEpisode, let restore = currentEpisode else {
      onScrubChange?(nil)
      return
    }
    onScrubChange?(
      ProgressTickScrubState(
        phase: isCancelling ? .cancel : .preview,
        target: target,
        restore: restore,
        canCommit: target.aired && !isCancelling
      )
    )
  }

  private func recenterWindow() {
    let size = visibleCount
    guard size > 0 else {
      windowStart = 0
      return
    }
    windowStart = min(max(currentIndex - size / 2, 0), max(episodes.count - size, 0))
  }

  private func clampWindow(to index: Int) {
    let size = visibleCount
    guard size > 0 else { return }
    if index < windowStart {
      windowStart = index
    } else if index >= windowStart + size {
      windowStart = index - size + 1
    }
    windowStart = min(max(windowStart, 0), max(episodes.count - size, 0))
  }

  private var bubbleX: CGFloat {
    tickCenterX(for: playheadIndex) - barWidth / 2
  }

  private var bubbleY: CGFloat {
    let detached = isCancelling ? min(max(lift - 12, 15), 36) : 0
    return -bubbleHeight - 8 - detached
  }

  private var leadingCaption: String {
    guard let first = visibleEpisodes.first else { return "" }
    return "EP.\(first.sort.episodeDisplay)"
  }

  private var trailingCaption: String {
    guard let last = visibleEpisodes.last else { return "" }
    if totalEpisodes > 0, Int(last.sort.rounded()) < totalEpisodes {
      return "\(totalEpisodes) 话 ▸"
    }
    return "EP.\(last.sort.episodeDisplay)"
  }

  private var captionAnchorIndex: Int {
    if isDragging && !isCancelling {
      return playheadIndex
    }
    return currentIndex
  }

  private var playheadCaptionText: String {
    let episode: EpisodeDTO?
    if isDragging && !isCancelling {
      episode = playheadEpisode
    } else {
      episode = currentEpisode
    }
    guard let episode else { return "" }
    return "看到 \(episode.sort.progressEpisodeNumber)"
  }

  private var centerCaptionColor: Color {
    isCancelling ? theme.secondaryText : theme.accent
  }

  @ViewBuilder
  private var playheadCaption: some View {
    let text = playheadCaptionText
    GeometryReader { geo in
      let width = geo.size.width
      let tickX = tickCenterX(for: captionAnchorIndex, width: width)
      let arrowW: CGFloat = 7
      let gap: CGFloat = 3
      let textW = monospacedCaptionWidth(text)
      let trailingReserve = monospacedCaptionWidth(trailingCaption) + 4
      let fitsRight = tickX + arrowW / 2 + gap + textW <= width - trailingReserve
      let textCenterX =
        fitsRight
        ? tickX + arrowW / 2 + gap + textW / 2
        : tickX - arrowW / 2 - gap - textW / 2
      let y = geo.size.height / 2
      ZStack {
        Image(systemName: "arrowtriangle.up.fill")
          .font(.system(size: 7, weight: .bold))
          .foregroundStyle(centerCaptionColor)
          .position(x: tickX, y: y)
        Text(text)
          .font(.system(size: 10, weight: .semibold, design: .monospaced))
          .foregroundStyle(centerCaptionColor)
          .fixedSize()
          .position(x: textCenterX, y: y)
      }
      .frame(width: width, height: geo.size.height)
    }
    .allowsHitTesting(false)
    .opacity(barWidth > 0 && !text.isEmpty ? 1 : 0)
    .animation(.snappy(duration: 0.16), value: captionAnchorIndex)
  }

  private func tickCenterX(for index: Int, width: CGFloat? = nil) -> CGFloat {
    let width = width ?? barWidth
    guard width > 0, visibleCount > 0 else { return 0 }
    let local = index - windowStart
    guard local >= 0, local < visibleCount else { return 0 }
    let gaps = ProgressTickMetrics.gap * CGFloat(visibleCount - 1)
    var flexes: [CGFloat] = []
    flexes.reserveCapacity(visibleCount)
    var totalFlex: CGFloat = 0
    for offset in 0..<visibleCount {
      let flex = tickFlex(abs((windowStart + offset) - playheadIndex))
      flexes.append(flex)
      totalFlex += flex
    }
    let unit = (width - gaps) / max(totalFlex, 1)
    var x: CGFloat = 0
    for offset in 0..<local {
      x += unit * flexes[offset] + ProgressTickMetrics.gap
    }
    return x + unit * flexes[local] / 2
  }

  private func monospacedCaptionWidth(_ text: String) -> CGFloat {
    let font = UIFont.monospacedSystemFont(ofSize: 10, weight: .semibold)
    return (text as NSString).size(withAttributes: [.font: font]).width
  }

  @ViewBuilder
  private func tick(_ episode: EpisodeDTO, index: Int, offset: Int) -> some View {
    let distance = abs(index - playheadIndex)
    let height = tickHeight(index: index, distance: distance)
    let isFirst = offset == 0
    let isLast = offset == visibleCount - 1
    let preview = isPreviewTick(index)
    let focus = magnifying && distance == 0
    let dashed = isCancelling && preview
    let shape = UnevenRoundedRectangle(
      cornerRadii: RectangleCornerRadii(
        topLeading: isFirst || focus ? 3 : 0,
        bottomLeading: isFirst || focus ? 3 : 0,
        bottomTrailing: isLast || focus ? 3 : 0,
        topTrailing: isLast || focus ? 3 : 0
      ),
      style: .continuous
    )

    shape
      .fill(tickStyle(episode, index: index, dashed: dashed, focus: focus))
      .overlay {
        if dashed {
          shape
            .strokeBorder(
              theme.accent.opacity(0.4),
              style: StrokeStyle(lineWidth: 1, dash: [3, 2])
            )
        } else if focus {
          shape
            .strokeBorder(theme.imageBorder, lineWidth: 2.5)
        }
      }
      .frame(maxWidth: tickWidth(distance: distance) == nil ? .infinity : nil)
      .frame(width: tickWidth(distance: distance), height: height)
      .shadow(
        color: tickShadowColor(index: index, focus: focus),
        radius: focus ? theme.ctaShadow.radius : theme.chipShadow.radius,
        y: focus ? theme.ctaShadow.y : theme.chipShadow.y
      )
      .animation(.spring(response: 0.18, dampingFraction: 0.55), value: playheadIndex)
  }

  private func tickWidth(distance: Int) -> CGFloat? {
    guard barWidth > 0, visibleCount > 0 else { return nil }
    let gaps = ProgressTickMetrics.gap * CGFloat(visibleCount - 1)
    var totalFlex: CGFloat = 0
    for offset in 0..<visibleCount {
      totalFlex += tickFlex(abs((windowStart + offset) - playheadIndex))
    }
    let unit = (barWidth - gaps) / max(totalFlex, 1)
    return unit * tickFlex(distance)
  }

  private func tickFlex(_ distance: Int) -> CGFloat {
    guard magnifying else { return 1 }
    switch distance {
    case 0:
      return 1.35
    case 1:
      return 1.15
    default:
      return 1
    }
  }

  private func tickHeight(index: Int, distance: Int) -> CGFloat {
    if !magnifying {
      return index == currentIndex
        ? ProgressTickMetrics.currentHeight
        : ProgressTickMetrics.idleHeight
    }
    switch distance {
    case 0:
      return ProgressTickMetrics.lensFocus
    case 1:
      return ProgressTickMetrics.lensNear
    case 2:
      return ProgressTickMetrics.lensOuter
    default:
      return ProgressTickMetrics.idleHeight
    }
  }

  private func isPreviewTick(_ index: Int) -> Bool {
    let low = min(currentIndex, playheadIndex)
    let high = max(currentIndex, playheadIndex)
    return index != currentIndex && index >= low && index <= high
  }

  private func tickShadowColor(index: Int, focus: Bool) -> Color {
    if focus {
      return theme.ctaShadow.color
    }
    if !isDragging, index == currentIndex {
      return theme.accent.opacity(0.4)
    }
    return .clear
  }

  private func tickStyle(
    _ episode: EpisodeDTO, index: Int, dashed: Bool, focus: Bool
  ) -> AnyShapeStyle {
    if dashed {
      return AnyShapeStyle(theme.accent.opacity(0.18))
    }
    if focus {
      return AnyShapeStyle(
        LinearGradient(colors: theme.ctaGradient, startPoint: .top, endPoint: .bottom)
      )
    }
    return AnyShapeStyle(tickFill(episode, index: index))
  }

  private func tickFill(_ episode: EpisodeDTO, index: Int) -> Color {
    let wish = theme.subjectTint(.book).text.opacity(0.5)
    let dropped = theme.episodeCell(.dropped).fill.first ?? theme.track
    if magnifying {
      let low = min(currentIndex, playheadIndex)
      let high = max(currentIndex, playheadIndex)
      if index > low && index < high {
        return theme.accent.opacity(0.5)
      }
    }
    if index <= currentIndex {
      switch episode.collectionTypeEnum {
      case .dropped:
        return dropped
      case .wish:
        return wish
      default:
        return theme.accent
      }
    }
    if episode.collectionTypeEnum == .wish {
      return wish
    }
    if episode.collectionTypeEnum == .dropped {
      return dropped
    }
    return episode.aired ? theme.accentDeep.opacity(0.32) : theme.track
  }
}

private struct ProgressTickBubble: View {
  let title: String
  let subtitle: String
  var detail: String? = nil
  var systemImage: String? = nil
  let isCancelling: Bool
  let showsArrow: Bool

  @Environment(\.theme) private var theme

  var body: some View {
    VStack(spacing: 0) {
      HStack(spacing: 9) {
        if isCancelling {
          if let systemImage {
            Image(systemName: systemImage)
              .font(.subheadline.weight(.heavy))
              .foregroundStyle(theme.toastText)
          }
          Text(title)
            .font(.subheadline.weight(.heavy))
            .foregroundStyle(theme.toastText)
          Text(subtitle)
            .font(.caption2.weight(.semibold))
            .foregroundStyle(theme.toastText.opacity(0.75))
        } else {
          Text(title)
            .font(.system(size: 13, weight: .heavy, design: .monospaced))
            .foregroundStyle(.white)
            .contentTransition(.numericText())
            .padding(.horizontal, 8)
            .frame(height: 24)
            .background(
              LinearGradient(
                colors: theme.ctaGradient, startPoint: .topLeading, endPoint: .bottomTrailing),
              in: Capsule()
            )
          VStack(alignment: .leading, spacing: 1) {
            if let detail, !detail.isEmpty {
              Text(detail)
                .font(.footnote.weight(.semibold))
                .foregroundStyle(theme.toastText)
                .lineLimit(1)
            }
            Text(subtitle)
              .font(.caption2.weight(.semibold))
              .foregroundStyle(theme.toastText.opacity(0.6))
          }
          .frame(maxWidth: 200, alignment: .leading)
          .fixedSize(horizontal: true, vertical: false)
        }
      }
      .padding(.leading, isCancelling ? 13 : 7)
      .padding(.trailing, 13)
      .padding(.vertical, 7)
      .background(
        bubbleColor,
        in: RoundedRectangle(cornerRadius: theme.metrics.controlRadius, style: .continuous)
      )
      .shadow(
        color: isCancelling ? theme.danger.opacity(0.35) : theme.heroShadow.color,
        radius: theme.heroShadow.radius,
        y: theme.heroShadow.y
      )

      if showsArrow {
        ProgressTickBubbleArrow()
          .fill(bubbleColor)
          .frame(width: 12, height: 6)
      }
    }
  }

  private var bubbleColor: Color {
    isCancelling ? theme.danger.opacity(0.92) : theme.toastFill
  }
}

private struct ProgressTickBubbleArrow: Shape {
  func path(in rect: CGRect) -> Path {
    Path { path in
      path.move(to: CGPoint(x: rect.midX, y: rect.maxY))
      path.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
      path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
      path.closeSubpath()
    }
  }
}

extension EpisodeDTO {
  fileprivate var tickAirCaption: String {
    if !aired {
      return "未播出 · \(waitDesc)"
    }
    if air.timeIntervalSince1970 == 0 {
      return "已播"
    }
    let days = Calendar.current.dateComponents([.day], from: air, to: Date()).day ?? 0
    if days <= 0 {
      return "已播 · 今天"
    }
    if days == 1 {
      return "已播 · 昨天"
    }
    if days < 7 {
      return "已播 · \(days) 天前"
    }
    return "已播"
  }
}

struct ProgressEpisodeChip: View {
  let episode: EpisodeDTO
  let kind: ProgressEpisodeTickKind
  var size: CGFloat = 34
  var cornerRadius: CGFloat = 10
  let interactionMode: EpisodeGridInteractionMode
  let subjectCollectionType: CollectionType
  var reload: (() async -> Void)? = nil

  @Environment(\.theme) private var theme
  @AppStorage("showEpisodeTrends") var showEpisodeTrends: Bool = true

  var body: some View {
    let label = chipLabel

    Group {
      switch interactionMode {
      case .contextMenu:
        label
          .contentShape(
            .contextMenuPreview,
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
          )
          .contextMenu {
            EpisodeUpdateMenu(
              episode: episode,
              subjectCollectionType: subjectCollectionType,
              reload: reload
            )
          } preview: {
            EpisodeInfoView(episode: episode)
              .padding()
              .frame(idealWidth: 360)
          }
      case .menu:
        Menu {
          EpisodeUpdateMenu(
            episode: episode,
            subjectCollectionType: subjectCollectionType,
            reload: reload,
            showsTitle: true
          )
        } label: {
          label
        }
        .buttonStyle(.plain)
      }
    }
  }

  private var style: EpisodeCellStyle {
    theme.episodeCell(kind.cellState)
  }

  private var shape: RoundedRectangle {
    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
  }

  private var chipLabel: some View {
    let cell = style
    return Text(verbatim: episode.sort.episodeDisplay)
      .font(.system(size: size > 22 ? 12 : 8.5, weight: .bold, design: .monospaced))
      .lineLimit(1)
      .foregroundStyle(cell.foreground)
      .padding(.horizontal, 2)
      .frame(minWidth: size, minHeight: size)
      .background {
        shape.fill(
          LinearGradient(
            colors: cell.fill,
            startPoint: .topLeading,
            endPoint: .bottomTrailing
          )
        )
      }
      .overlay {
        if showEpisodeTrends, episode.comment > 0 {
          shape.fill(
            LinearGradient(
              stops: [
                .init(color: .clear, location: 0.55),
                .init(color: Color(hex: 0xFF8040, opacity: 0.55 * episode.trendLevel), location: 1),
              ],
              startPoint: .top,
              endPoint: .bottom
            )
          )
          .allowsHitTesting(false)
        }
      }
      .overlay {
        if cell.dashed {
          shape.strokeBorder(
            cell.border,
            style: StrokeStyle(lineWidth: cell.borderWidth, dash: [4, 3])
          )
        } else {
          shape.strokeBorder(cell.border, lineWidth: cell.borderWidth)
        }
      }
      .strikethrough(cell.strikethrough)
  }
}
