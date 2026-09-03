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

enum ProgressTickAction: Equatable, Identifiable {
  case cancel
  case status(EpisodeCollectionType)
  case discuss

  var id: String {
    switch self {
    case .cancel:
      "cancel"
    case .status(let type):
      "status.\(type.rawValue)"
    case .discuss:
      "discuss"
    }
  }

  var title: String {
    switch self {
    case .cancel:
      "取消"
    case .status(let type):
      type.action
    case .discuss:
      "讨论"
    }
  }

  var icon: String {
    switch self {
    case .cancel:
      "xmark"
    case .status(let type):
      type.icon
    case .discuss:
      "bubble"
    }
  }
}

enum ProgressTickCommit: Equatable {
  case watchUntil
  case status(EpisodeCollectionType)
}

struct ProgressTickScrubState: Equatable {
  enum Phase: Equatable {
    case preview
    case rail(ProgressTickAction)
  }

  var phase: Phase
  var target: EpisodeDTO
  var restore: EpisodeDTO?
  var canCommit: Bool
}

struct ProgressEpisodeTrackView: View {
  let episodes: [EpisodeDTO]
  let totalEpisodes: Int
  let interactionMode: EpisodeGridInteractionMode
  let subjectCollectionType: CollectionType
  var reload: (() async -> Void)? = nil
  var onScrubChange: ((ProgressTickScrubState?) -> Void)? = nil
  var onScrubCommit: ((EpisodeDTO, ProgressTickCommit) async -> Bool)? = nil

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
private final class ScrubHaptics {
  enum Tick {
    case regular
    case soft
    case home
    case detent
  }

  private let selection = UISelectionFeedbackGenerator()
  private let soft = UIImpactFeedbackGenerator(style: .soft)
  private let light = UIImpactFeedbackGenerator(style: .light)
  private let medium = UIImpactFeedbackGenerator(style: .medium)
  private let rigid = UIImpactFeedbackGenerator(style: .rigid)
  private let heavy = UIImpactFeedbackGenerator(style: .heavy)
  private let notification = UINotificationFeedbackGenerator()
  private var lastID: Int?
  private var lastTickAt: TimeInterval = 0

  func prepare() {
    lastID = nil
    selection.prepare()
    medium.prepare()
  }

  func arm() {
    medium.impactOccurred()
    selection.prepare()
    soft.prepare()
    light.prepare()
    rigid.prepare()
    heavy.prepare()
  }

  func tick(_ id: Int, kind: Tick) {
    guard id != lastID else { return }
    lastID = id
    let now = Date().timeIntervalSinceReferenceDate
    switch kind {
    case .regular, .soft:
      guard now - lastTickAt >= ProgressTickMetrics.tickHapticInterval else { return }
      if kind == .soft {
        soft.impactOccurred(intensity: 0.55)
        soft.prepare()
      } else {
        selection.selectionChanged()
        selection.prepare()
      }
    case .home:
      medium.impactOccurred(intensity: 0.75)
      medium.prepare()
    case .detent:
      rigid.impactOccurred(intensity: 0.9)
      rigid.prepare()
    }
    lastTickAt = now
  }

  func boundary() {
    rigid.impactOccurred(intensity: 1)
    rigid.prepare()
  }

  func railMove() {
    rigid.impactOccurred(intensity: 0.8)
    rigid.prepare()
  }

  func tearOff() {
    heavy.impactOccurred()
    light.prepare()
  }

  func reattach() {
    light.impactOccurred(intensity: 0.7)
    heavy.prepare()
  }

  func release(committed: Bool) {
    if committed {
      light.impactOccurred()
      notification.prepare()
    } else {
      soft.impactOccurred(intensity: 0.6)
    }
  }

  func success() {
    notification.notificationOccurred(.success)
  }

  func failure() {
    notification.notificationOccurred(.error)
  }
}

private enum ProgressTickMetrics {
  static let maxVisible = 24
  static let gap: CGFloat = 2
  static let idleHeight: CGFloat = 12
  static let currentHeight: CGFloat = 16
  static let pressHeight: CGFloat = 18
  static let lensOuter: CGFloat = 13
  static let lensNear: CGFloat = 15
  static let lensFocus: CGFloat = 22
  static let reservedHeight: CGFloat = 22
  static let hitSlop: CGFloat = 8
  static let railEnter: CGFloat = 26
  static let railExit: CGFloat = 8
  static let fanRadius: CGFloat = 100
  static let fanLift: CGFloat = 20
  static let fanItem: CGFloat = 42
  static let fanDeadZone: CGFloat = 16
  static let fanHysteresis: CGFloat = 4 * .pi / 180
  static let fanLabelRoom: CGFloat = 28
  static let fanStartAngle: CGFloat = 160 * .pi / 180
  static let fanEndAngle: CGFloat = 20 * .pi / 180
  static let fanEdgeRadius: CGFloat = 140
  static let fanEdgeEndAngle: CGFloat = 10 * .pi / 180

  static func fanEdgeAngles(count: Int, trailing: Bool) -> [CGFloat] {
    guard count > 1 else { return [.pi / 2] }
    let sweep = .pi / 2 - fanEdgeEndAngle
    return (0..<count).map {
      let delta = sweep * CGFloat($0) / CGFloat(count - 1)
      return trailing ? .pi / 2 + delta : .pi / 2 - delta
    }
  }

  static func fanAngles(count: Int) -> [CGFloat] {
    guard count > 1 else { return [.pi / 2] }
    return (0..<count).map {
      fanStartAngle - (fanStartAngle - fanEndAngle) * CGFloat($0) / CGFloat(count - 1)
    }
  }
  static let pullLimit: CGFloat = 14
  static let edgeHot: CGFloat = 26
  static let rubberLimit: CGFloat = 16
  static let boundaryTrigger: CGFloat = 6
  static let tickHapticInterval: TimeInterval = 0.045
}

struct ProgressEpisodeTicksView: View {
  let episodes: [EpisodeDTO]
  let totalEpisodes: Int
  var onScrubChange: ((ProgressTickScrubState?) -> Void)? = nil
  var onScrubCommit: ((EpisodeDTO, ProgressTickCommit) async -> Bool)? = nil

  @AppStorage("titlePreference") var titlePreference: TitlePreference = .original
  @Environment(\.theme) private var theme
  @Environment(\.openURL) private var openURL

  @State private var barWidth: CGFloat = 0
  @State private var windowStart: Int = 0
  @State private var scrubIndex: Int?
  @State private var pendingIndex: Int?
  @State private var pendingCommit: ProgressTickCommit?
  @State private var pressing = false
  @State private var isDragging = false
  @State private var onRail = false
  @State private var railIndex = 0
  @State private var railOrigin: CGPoint = .zero
  @State private var fingerY: CGFloat = 0
  @State private var fingerX: CGFloat = 0
  @State private var lift: CGFloat = 0
  @State private var overshoot: CGFloat = 0
  @State private var bubbleSize: CGSize = .zero
  @GestureState private var touchActive = false
  @State private var edgeHoldTask: Task<Void, Never>?
  @State private var edgeHoldDirection: Int = 0
  @State private var haptics = ScrubHaptics()

  private var currentIndex: Int {
    episodes.lastIndex(where: { $0.collectionTypeEnum == .collect }) ?? -1
  }

  private var anchorIndex: Int {
    let index = pendingCommit == .watchUntil ? pendingIndex ?? currentIndex : currentIndex
    return min(max(index, -1), max(episodes.count - 1, 0))
  }

  private var playheadIndex: Int {
    min(max(scrubIndex ?? anchorIndex, 0), max(episodes.count - 1, 0))
  }

  private var currentEpisode: EpisodeDTO? {
    episodes.indices.contains(currentIndex) ? episodes[currentIndex] : nil
  }

  private var anchorEpisode: EpisodeDTO? {
    episodes.indices.contains(anchorIndex) ? episodes[anchorIndex] : currentEpisode
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
    isDragging
  }

  private var previewing: Bool {
    isDragging && !onRail
  }

  private var liftProgress: CGFloat {
    onRail ? 1 : min(lift / ProgressTickMetrics.railEnter, 1)
  }

  private struct FanPlan {
    var originX: CGFloat
    var radius: CGFloat
    var actions: [ProgressTickAction]
    var angles: [CGFloat]
  }

  private var baseActions: [ProgressTickAction] {
    guard let episode = playheadEpisode else { return [.cancel, .discuss] }
    let others = episode.collectionTypeEnum.otherTypes()
    guard others.count == 3 else { return [.cancel] + others.map { .status($0) } + [.discuss] }
    return [.status(others[1]), .status(others[0]), .cancel, .discuss, .status(others[2])]
  }

  private var fanPlan: FanPlan {
    let actions = baseActions
    let tickX = tickCenterX(for: playheadIndex)
    let reach =
      ProgressTickMetrics.fanRadius * abs(cos(ProgressTickMetrics.fanStartAngle))
      + ProgressTickMetrics.fanItem / 2 + 2
    let cancelAt = actions.firstIndex(of: .cancel) ?? actions.count / 2
    let leading = Array(actions[..<cancelAt])
    let trailing = Array(actions[(cancelAt + 1)...])
    if tickX < reach, tickX < barWidth - reach {
      let ordered = [ProgressTickAction.cancel] + trailing + leading
      return FanPlan(
        originX: tickX,
        radius: ProgressTickMetrics.fanEdgeRadius,
        actions: ordered,
        angles: ProgressTickMetrics.fanEdgeAngles(count: ordered.count, trailing: false)
      )
    }
    if tickX > barWidth - reach, tickX > reach {
      let ordered = [ProgressTickAction.cancel] + leading.reversed() + trailing.reversed()
      return FanPlan(
        originX: tickX,
        radius: ProgressTickMetrics.fanEdgeRadius,
        actions: ordered,
        angles: ProgressTickMetrics.fanEdgeAngles(count: ordered.count, trailing: true)
      )
    }
    return FanPlan(
      originX: min(max(tickX, reach), max(barWidth - reach, reach)),
      radius: ProgressTickMetrics.fanRadius,
      actions: actions,
      angles: ProgressTickMetrics.fanAngles(count: actions.count)
    )
  }

  private var railActions: [ProgressTickAction] {
    fanPlan.actions
  }

  private var railDefaultIndex: Int {
    railActions.firstIndex(of: .cancel) ?? railActions.count / 2
  }

  private var railAction: ProgressTickAction {
    let actions = railActions
    return actions[min(max(railIndex, 0), actions.count - 1)]
  }

  private var edgeDepth: CGFloat {
    guard barWidth > 0 else { return 0 }
    let distance = min(fingerX, barWidth - fingerX)
    return min(max(1 - distance / ProgressTickMetrics.edgeHot, 0), 1)
  }

  private var bandOffset: CGFloat {
    overshoot < 0
      ? -rubber(-overshoot, limit: ProgressTickMetrics.rubberLimit)
      : rubber(overshoot, limit: ProgressTickMetrics.rubberLimit)
  }

  var body: some View {
    VStack(spacing: 5) {
      tickBar
        .overlay(alignment: .top) {
          bubbleOverlay
        }
        .overlay(alignment: .top) {
          fanOverlay
        }
        .zIndex(isDragging ? 2 : 0)

      let placement = captionPlacement(width: barWidth)
      HStack {
        Text(leadingCaption)
          .contentTransition(.numericText())
          .opacity(placement?.hidesLeading == true ? 0 : 1)
        Spacer(minLength: 0)
        Text(trailingCaption)
          .contentTransition(.numericText())
          .opacity(placement?.hidesTrailing == true ? 0 : 1)
      }
      .font(.system(size: 10, weight: .semibold, design: .monospaced))
      .foregroundStyle(theme.tertiaryText)
      .animation(.easeOut(duration: 0.15), value: placement?.hidesLeading)
      .animation(.easeOut(duration: 0.15), value: placement?.hidesTrailing)
      .overlay {
        playheadCaption
      }
    }
    .onAppear {
      recenterWindow()
      haptics.prepare()
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
    .offset(x: bandOffset)
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
    .padding(.vertical, ProgressTickMetrics.hitSlop)
    .contentShape(Rectangle())
    .gesture(scrubGesture)
    .padding(.vertical, -ProgressTickMetrics.hitSlop)
    .onChange(of: touchActive) { _, active in
      guard !active else { return }
      if pressing {
        withAnimation(.spring(response: 0.24, dampingFraction: 0.8)) {
          pressing = false
        }
      }
      Task { @MainActor in
        try? await Task.sleep(for: .milliseconds(150))
        if !touchActive, isDragging {
          resetScrub()
        }
      }
    }
  }

  @ViewBuilder
  private var bubbleOverlay: some View {
    if previewing, let episode = playheadEpisode {
      let tether = tetherHeight
      VStack(spacing: 0) {
        ProgressTickBubble(
          title: "EP.\(episode.sort.episodeDisplay)",
          subtitle: episode.tickAirCaption,
          detail: titlePreference.title(name: episode.name, nameCN: episode.nameCN),
          arrowOffset: bubbleArrowOffset
        )
        if tether > 0 {
          Canvas { context, size in
            var path = Path()
            path.move(to: CGPoint(x: size.width / 2, y: 0))
            path.addLine(to: CGPoint(x: size.width / 2, y: size.height))
            context.stroke(
              path,
              with: .color(theme.accent.opacity(0.45)),
              style: StrokeStyle(lineWidth: 1.5, dash: [3, 3])
            )
          }
          .frame(width: 2, height: tether)
        }
      }
      .onGeometryChange(for: CGSize.self) { proxy in
        proxy.size
      } action: { size in
        bubbleSize = size
      }
      .offset(x: bubbleX, y: bubbleY)
      .allowsHitTesting(false)
      .transition(
        .scale(scale: 0.72, anchor: .bottom)
          .combined(with: .opacity)
      )
    }
  }

  private var fanHeight: CGFloat {
    ProgressTickMetrics.fanLift + ProgressTickMetrics.fanEdgeRadius
      + ProgressTickMetrics.fanItem / 2 + ProgressTickMetrics.fanLabelRoom
  }

  @ViewBuilder
  private var fanOverlay: some View {
    if isDragging, barWidth > 0 {
      let height = fanHeight
      let plan = fanPlan
      let originX = plan.originX
      let originY = height - ProgressTickMetrics.fanLift
      let radius = plan.radius
      ZStack {
        ForEach(Array(plan.actions.enumerated()), id: \.element.id) { offset, action in
          let angle = plan.angles[offset]
          let target = CGPoint(
            x: originX + radius * cos(angle), y: originY - radius * sin(angle))
          ProgressTickFanItem(action: action, selected: onRail && action == railAction)
            .position(onRail ? target : CGPoint(x: originX, y: height))
            .scaleEffect(onRail ? 1 : 0.35)
            .opacity(onRail ? 1 : 0)
            .animation(
              .spring(response: 0.36, dampingFraction: 0.72)
                .delay(onRail ? Double(offset) * 0.028 : 0),
              value: onRail
            )
        }
      }
      .frame(width: barWidth, height: height)
      .offset(y: -height)
      .allowsHitTesting(false)
    }
  }

  private var edgeGlow: some View {
    let leading = fingerX < ProgressTickMetrics.edgeHot && windowStart > 0
    let trailing =
      fingerX > barWidth - ProgressTickMetrics.edgeHot
      && windowStart + visibleCount < episodes.count
    let strength = 0.16 + 0.24 * edgeDepth
    return ZStack {
      LinearGradient(
        colors: [theme.accent.opacity(strength), .clear],
        startPoint: .leading,
        endPoint: .trailing
      )
      .frame(width: ProgressTickMetrics.edgeHot)
      .frame(maxWidth: .infinity, alignment: .leading)
      .opacity(leading ? 1 : 0)

      LinearGradient(
        colors: [.clear, theme.accent.opacity(strength)],
        startPoint: .leading,
        endPoint: .trailing
      )
      .frame(width: ProgressTickMetrics.edgeHot)
      .frame(maxWidth: .infinity, alignment: .trailing)
      .opacity(trailing ? 1 : 0)
    }
    .padding(.vertical, -4)
    .allowsHitTesting(false)
  }

  private var scrubGesture: some Gesture {
    LongPressGesture(minimumDuration: 0.2)
      .sequenced(
        before: DragGesture(minimumDistance: 0, coordinateSpace: .local)
      )
      .updating($touchActive) { _, state, _ in
        state = true
      }
      .onChanged { value in
        switch value {
        case .first(true):
          beginPress()
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

  private func beginPress() {
    guard !pressing, !isDragging, pendingIndex == nil else { return }
    withAnimation(.spring(response: 0.24, dampingFraction: 0.8)) {
      pressing = true
    }
    haptics.prepare()
  }

  private func armScrub() {
    guard !isDragging, pendingIndex == nil else { return }
    scrubIndex = max(anchorIndex, 0)
    withAnimation(.spring(response: 0.32, dampingFraction: 0.72)) {
      pressing = false
      isDragging = true
      onRail = false
      lift = 0
      overshoot = 0
    }
    haptics.arm()
    reportScrub()
  }

  private func handleDrag(_ drag: DragGesture.Value) {
    guard isDragging else { return }
    let rawX = drag.location.x
    fingerX = min(max(0, rawX), max(barWidth, 1))
    fingerY = drag.location.y - ProgressTickMetrics.hitSlop
    lift = max(0, -drag.translation.height)
    updateRailPhase()

    if onRail {
      moveRail(to: CGPoint(x: rawX, y: fingerY))
      reportScrub()
      return
    }

    let leadingHot = fingerX < ProgressTickMetrics.edgeHot && windowStart > 0
    let trailingHot =
      fingerX > barWidth - ProgressTickMetrics.edgeHot
      && windowStart + visibleCount < episodes.count
    if trailingHot {
      applyPlayhead(windowStart + visibleCount - 1)
      startEdgeHold(+1)
    } else if leadingHot {
      applyPlayhead(windowStart)
      startEdgeHold(-1)
    } else {
      stopEdgeHold()
      if let index = tickIndex(at: fingerX) {
        applyPlayhead(index)
      }
    }
    updateOvershoot(rawX)
    reportScrub()
  }

  private func updateRailPhase() {
    let nowOnRail =
      onRail
      ? fingerY < ProgressTickMetrics.railExit
      : lift > ProgressTickMetrics.railEnter
    guard nowOnRail != onRail else { return }
    if nowOnRail {
      stopEdgeHold()
      railOrigin = CGPoint(x: fingerX, y: fingerY + lift)
      railIndex = railDefaultIndex
    }
    withAnimation(.spring(response: 0.26, dampingFraction: 0.8)) {
      onRail = nowOnRail
      if nowOnRail {
        overshoot = 0
      }
    }
    if nowOnRail {
      haptics.tearOff()
    } else {
      haptics.reattach()
    }
  }

  private func moveRail(to location: CGPoint) {
    let count = railActions.count
    guard count > 0 else { return }
    let dx = location.x - railOrigin.x
    let dy = railOrigin.y - location.y
    guard hypot(dx, dy) >= ProgressTickMetrics.fanDeadZone else { return }
    var angle = atan2(dy, dx)
    if angle < 0 {
      angle = dx < 0 ? .pi : 0
    }
    let angles = fanPlan.angles
    let current = angles[min(max(railIndex, 0), count - 1)]
    let half = count > 1 ? abs(angles[0] - angles[1]) / 2 : .pi
    guard abs(angle - current) > half + ProgressTickMetrics.fanHysteresis else { return }
    guard
      let candidate = angles.indices.min(by: { abs(angles[$0] - angle) < abs(angles[$1] - angle) }),
      candidate != railIndex
    else { return }
    withAnimation(.spring(response: 0.22, dampingFraction: 0.72)) {
      railIndex = candidate
    }
    haptics.railMove()
  }

  private func updateOvershoot(_ rawX: CGFloat) {
    let atStart = windowStart == 0 && playheadIndex == 0
    let atEnd =
      windowStart + visibleCount >= episodes.count && playheadIndex == episodes.count - 1
    var over: CGFloat = 0
    if rawX < 0, atStart {
      over = rawX
    } else if rawX > barWidth, atEnd {
      over = rawX - barWidth
    }
    if abs(over) >= ProgressTickMetrics.boundaryTrigger,
      abs(overshoot) < ProgressTickMetrics.boundaryTrigger
    {
      haptics.boundary()
    }
    overshoot = over
  }

  private func tickIndex(at x: CGFloat) -> Int? {
    guard let layout = tickLayout() else { return nil }
    var cursor: CGFloat = 0
    for offset in 0..<visibleCount {
      let width = layout.unit * layout.flexes[offset]
      if x < cursor + width + ProgressTickMetrics.gap / 2 {
        return windowStart + offset
      }
      cursor += width + ProgressTickMetrics.gap
    }
    return windowStart + visibleCount - 1
  }

  private func applyPlayhead(_ index: Int) {
    let clamped = min(max(index, 0), max(episodes.count - 1, 0))
    if scrubIndex != clamped {
      withAnimation(.snappy(duration: 0.16)) {
        scrubIndex = clamped
        clampWindow(to: clamped)
      }
      if episodes.indices.contains(clamped) {
        haptics.tick(episodes[clamped].id, kind: tickKind(at: clamped))
      }
    } else if edgeHoldDirection != 0, clamped == 0 || clamped == episodes.count - 1 {
      stopEdgeHold()
    }
  }

  private func tickKind(at index: Int) -> ScrubHaptics.Tick {
    if index == 0 || index == episodes.count - 1 {
      return .detent
    }
    if !episodes[index].aired {
      return .soft
    }
    if index == currentIndex {
      return .home
    }
    if episodes.indices.contains(index + 1), !episodes[index + 1].aired {
      return .detent
    }
    return .regular
  }

  private func canCommit(_ index: Int) -> Bool {
    guard episodes.indices.contains(index), episodes[index].aired else { return false }
    return episodes[...index].contains { $0.collectionTypeEnum != .collect }
  }

  private func startEdgeHold(_ direction: Int) {
    guard edgeHoldDirection != direction else { return }
    stopEdgeHold()
    edgeHoldDirection = direction
    let startedAt = Date()
    edgeHoldTask = Task { @MainActor in
      while !Task.isCancelled {
        let elapsed = Date().timeIntervalSince(startedAt)
        let ramp = min(max((elapsed - 0.4) / 1.8, 0), 1)
        let base = 6 + 42 * ramp * ramp * (3 - 2 * ramp)
        let rate = base * (0.75 + 0.5 * Double(edgeDepth))
        try? await Task.sleep(for: .milliseconds(Int(1000 / rate)))
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
    let wasDragging = isDragging
    let index = playheadIndex
    let target = playheadEpisode
    let action: ProgressTickAction? = wasDragging && onRail ? railAction : nil
    var commit: ProgressTickCommit?
    if wasDragging, !onRail, canCommit(index) {
      commit = .watchUntil
    } else if case .status(let type) = action {
      commit = .status(type)
    }
    withAnimation(.spring(response: 0.28, dampingFraction: 0.78)) {
      pressing = false
      isDragging = false
      onRail = false
      lift = 0
      overshoot = 0
      scrubIndex = nil
      if commit != nil {
        pendingIndex = index
        pendingCommit = commit
      }
    }
    onScrubChange?(nil)
    if let commit, let target {
      haptics.release(committed: true)
      Task { @MainActor in
        await runCommit(target, commit)
      }
    } else if action == .discuss, let target, let url = URL(string: target.link) {
      haptics.release(committed: true)
      openURL(url)
    } else if wasDragging {
      haptics.release(committed: false)
    }
  }

  private func runCommit(_ target: EpisodeDTO, _ commit: ProgressTickCommit) async {
    let committed = await onScrubCommit?(target, commit) ?? false
    withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) {
      pendingIndex = nil
      pendingCommit = nil
    }
    if committed {
      haptics.success()
    } else {
      haptics.failure()
    }
  }

  private func resetScrub() {
    stopEdgeHold()
    scrubIndex = nil
    pressing = false
    isDragging = false
    onRail = false
    lift = 0
    overshoot = 0
    onScrubChange?(nil)
    haptics.prepare()
  }

  private func reportScrub() {
    guard isDragging, let target = playheadEpisode else {
      onScrubChange?(nil)
      return
    }
    onScrubChange?(
      ProgressTickScrubState(
        phase: onRail ? .rail(railAction) : .preview,
        target: target,
        restore: currentEpisode,
        canCommit: !onRail && canCommit(playheadIndex)
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

  private func rubber(_ value: CGFloat, limit: CGFloat) -> CGFloat {
    guard value > 0 else { return 0 }
    return limit * value / (value + limit)
  }

  private var tetherHeight: CGFloat {
    let pull = rubber(lift, limit: ProgressTickMetrics.pullLimit)
    return pull > 1 ? pull : 0
  }

  private var bubbleCenterX: CGFloat {
    let half = bubbleSize.width / 2
    let overhang: CGFloat = 20
    let lower = half - overhang
    let upper = barWidth - half + overhang
    guard lower < upper else { return barWidth / 2 }
    return min(max(tickCenterX(for: playheadIndex), lower), upper)
  }

  private var bubbleArrowOffset: CGFloat {
    let limit = max(bubbleSize.width / 2 - 16, 0)
    return min(max(tickCenterX(for: playheadIndex) - bubbleCenterX, -limit), limit)
  }

  private var bubbleX: CGFloat {
    bubbleCenterX - barWidth / 2
  }

  private var bubbleY: CGFloat {
    return -bubbleSize.height - 8
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
    previewing ? playheadIndex : anchorIndex
  }

  private var playheadCaptionText: String {
    guard let episode = previewing ? playheadEpisode : anchorEpisode else { return "" }
    return "看到 \(episode.sort.progressEpisodeNumber)"
  }

  private var centerCaptionColor: Color {
    onRail ? theme.secondaryText : theme.accent
  }

  private struct CaptionPlacement {
    var tickX: CGFloat
    var textCenterX: CGFloat
    var hidesLeading: Bool
    var hidesTrailing: Bool
  }

  private func captionPlacement(width: CGFloat) -> CaptionPlacement? {
    let text = playheadCaptionText
    guard width > 0, !text.isEmpty else { return nil }
    let tickX = tickCenterX(for: captionAnchorIndex, width: width)
    let arrowW: CGFloat = 7
    let gap: CGFloat = 3
    let margin: CGFloat = 4
    let textW = monospacedCaptionWidth(text)
    let leadingEnd = monospacedCaptionWidth(leadingCaption) + margin
    let trailingStart = width - monospacedCaptionWidth(trailingCaption) - margin
    let rightStart = tickX + arrowW / 2 + gap
    let leftEnd = tickX - arrowW / 2 - gap
    let fitsRight = rightStart + textW <= trailingStart
    let fitsLeft = leftEnd - textW >= leadingEnd
    let placeRight = fitsRight || (!fitsLeft && rightStart + textW <= width)
    let textCenterX = placeRight ? rightStart + textW / 2 : leftEnd - textW / 2
    let minX = min(tickX - arrowW / 2, textCenterX - textW / 2)
    let maxX = max(tickX + arrowW / 2, textCenterX + textW / 2)
    return CaptionPlacement(
      tickX: tickX,
      textCenterX: textCenterX,
      hidesLeading: minX < leadingEnd,
      hidesTrailing: maxX > trailingStart
    )
  }

  @ViewBuilder
  private var playheadCaption: some View {
    let text = playheadCaptionText
    GeometryReader { geo in
      if let placement = captionPlacement(width: geo.size.width) {
        let y = geo.size.height / 2
        ZStack {
          Image(systemName: "arrowtriangle.up.fill")
            .font(.system(size: 7, weight: .bold))
            .foregroundStyle(centerCaptionColor)
            .position(x: placement.tickX, y: y)
          Text(text)
            .font(.system(size: 10, weight: .semibold, design: .monospaced))
            .foregroundStyle(centerCaptionColor)
            .fixedSize()
            .position(x: placement.textCenterX, y: y)
        }
        .frame(width: geo.size.width, height: geo.size.height)
      }
    }
    .allowsHitTesting(false)
    .animation(.snappy(duration: 0.16), value: captionAnchorIndex)
  }

  private func tickLayout(width: CGFloat? = nil) -> (unit: CGFloat, flexes: [CGFloat])? {
    let width = width ?? barWidth
    guard width > 0, visibleCount > 0 else { return nil }
    var flexes: [CGFloat] = []
    flexes.reserveCapacity(visibleCount)
    var totalFlex: CGFloat = 0
    for offset in 0..<visibleCount {
      let flex = tickFlex(abs((windowStart + offset) - playheadIndex))
      flexes.append(flex)
      totalFlex += flex
    }
    let gaps = ProgressTickMetrics.gap * CGFloat(visibleCount - 1)
    return ((width - gaps) / max(totalFlex, 1), flexes)
  }

  private func tickCenterX(for index: Int, width: CGFloat? = nil) -> CGFloat {
    guard let layout = tickLayout(width: width) else { return 0 }
    let local = index - windowStart
    guard local >= 0, local < visibleCount else { return 0 }
    var x: CGFloat = 0
    for offset in 0..<local {
      x += layout.unit * layout.flexes[offset] + ProgressTickMetrics.gap
    }
    return x + layout.unit * layout.flexes[local] / 2
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
    let focus = magnifying && distance == 0
    let dashed = onRail && focus && railAction == .status(.none)
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
              theme.accent.opacity(0.5),
              style: StrokeStyle(lineWidth: 1.5, dash: [3, 2])
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
      .animation(.spring(response: 0.2, dampingFraction: 0.68), value: playheadIndex)
      .animation(.smooth(duration: 0.28), value: currentIndex)
      .animation(.smooth(duration: 0.2), value: railAction)
  }

  private func tickWidth(distance: Int) -> CGFloat? {
    guard let layout = tickLayout() else { return nil }
    return layout.unit * tickFlex(distance)
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
      guard index == anchorIndex else { return ProgressTickMetrics.idleHeight }
      return pressing ? ProgressTickMetrics.pressHeight : ProgressTickMetrics.currentHeight
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

  private func tickShadowColor(index: Int, focus: Bool) -> Color {
    if focus {
      return theme.ctaShadow.color
    }
    if !isDragging, index == anchorIndex {
      return theme.accent.opacity(pressing ? 0.55 : 0.4)
    }
    return .clear
  }

  private func tickStyle(
    _ episode: EpisodeDTO, index: Int, dashed: Bool, focus: Bool
  ) -> AnyShapeStyle {
    if dashed {
      return AnyShapeStyle(theme.accent.opacity(0.18))
    }
    if focus, onRail {
      return AnyShapeStyle(railFocusFill(episode, index: index))
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
    if previewing {
      let low = min(currentIndex, playheadIndex)
      let high = max(currentIndex, playheadIndex)
      if index > low && index < high {
        return theme.accent.opacity(0.5 - 0.22 * liftProgress)
      }
    }
    if let pendingIndex, let pendingCommit {
      switch pendingCommit {
      case .watchUntil:
        if index > currentIndex, index <= pendingIndex {
          return theme.accent.opacity(0.55)
        }
      case .status(let type):
        if index == pendingIndex {
          return statusFill(type, episode: episode).opacity(0.7)
        }
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

  private func statusFill(_ type: EpisodeCollectionType, episode: EpisodeDTO) -> Color {
    switch type {
    case .collect:
      return theme.accent
    case .wish:
      return theme.subjectTint(.book).text.opacity(0.8)
    case .dropped:
      return theme.episodeCell(.dropped).fill.first ?? theme.track
    case .none:
      return episode.aired ? theme.accentDeep.opacity(0.32) : theme.track
    }
  }

  private func railFocusFill(_ episode: EpisodeDTO, index: Int) -> Color {
    switch railAction {
    case .cancel, .discuss:
      return tickFill(episode, index: index)
    case .status(let type):
      return statusFill(type, episode: episode)
    }
  }
}

private struct ProgressTickBubble: View {
  let title: String
  let subtitle: String
  var detail: String? = nil
  var arrowOffset: CGFloat = 0

  @Environment(\.theme) private var theme

  var body: some View {
    VStack(spacing: 0) {
      VStack(alignment: .leading, spacing: 2) {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
          Text(title)
            .font(.system(size: 15, weight: .heavy, design: .monospaced))
            .foregroundStyle(theme.toastText)
            .contentTransition(.numericText())
          if let detail, !detail.isEmpty {
            Text(detail)
              .font(.footnote.weight(.semibold))
              .foregroundStyle(theme.toastText)
              .lineLimit(1)
          }
        }
        Text(subtitle)
          .font(.caption2.weight(.semibold))
          .foregroundStyle(theme.toastText.opacity(0.6))
      }
      .frame(maxWidth: 240, alignment: .leading)
      .fixedSize(horizontal: true, vertical: false)
      .padding(.horizontal, 13)
      .padding(.vertical, 8)
      .background(
        theme.toastFill,
        in: RoundedRectangle(cornerRadius: theme.metrics.controlRadius, style: .continuous)
      )
      .shadow(
        color: theme.heroShadow.color,
        radius: theme.heroShadow.radius,
        y: theme.heroShadow.y
      )

      ProgressTickBubbleArrow()
        .fill(theme.toastFill)
        .frame(width: 12, height: 6)
        .offset(x: arrowOffset)
    }
  }
}

private struct ProgressTickFanItem: View {
  let action: ProgressTickAction
  let selected: Bool

  @Environment(\.theme) private var theme

  private var destructive: Bool {
    action == .cancel || action == .status(.dropped)
  }

  var body: some View {
    ZStack {
      Circle()
        .fill(fill)
        .overlay {
          Circle().strokeBorder(theme.imageBorder, lineWidth: 1)
        }
        .shadow(
          color: selected ? theme.ctaShadow.color : theme.heroShadow.color,
          radius: theme.heroShadow.radius,
          y: theme.heroShadow.y
        )
      Image(systemName: action.icon)
        .font(.system(size: 16, weight: .bold))
        .foregroundStyle(selected ? .white : theme.toastText)
    }
    .frame(width: ProgressTickMetrics.fanItem, height: ProgressTickMetrics.fanItem)
    .scaleEffect(selected ? 1.18 : 1)
    .overlay(alignment: .top) {
      if selected {
        Text(action.title)
          .font(.caption2.weight(.bold))
          .foregroundStyle(theme.toastText)
          .padding(.horizontal, 8)
          .padding(.vertical, 3)
          .background(theme.toastFill, in: Capsule())
          .fixedSize()
          .offset(y: -ProgressTickMetrics.fanLabelRoom)
          .transition(.scale(scale: 0.6, anchor: .bottom).combined(with: .opacity))
      }
    }
    .animation(.spring(response: 0.24, dampingFraction: 0.7), value: selected)
  }

  private var fill: AnyShapeStyle {
    guard selected else { return AnyShapeStyle(theme.toastFill) }
    if destructive {
      return AnyShapeStyle(theme.danger)
    }
    return AnyShapeStyle(
      LinearGradient(colors: theme.ctaGradient, startPoint: .top, endPoint: .bottom))
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
