import SwiftUI

extension Float {
  var progressEpisodeNumber: String {
    if truncatingRemainder(dividingBy: 1) == 0 {
      return String(Int(self))
    }
    return episodeDisplay
  }
}

struct GlassProgressCard: View {
  let payload: ProgressSubjectRenderPayload
  let interactionMode: EpisodeGridInteractionMode
  let reload: () async -> Void

  @AppStorage("titlePreference") private var titlePreference: TitlePreference = .original
  @AppStorage("subjectImageQuality") private var subjectImageQuality: ImageQuality = .high

  @Environment(\.theme) private var theme

  private var subject: SubjectDTO {
    payload.item.subject
  }

  private var coverHeight: CGFloat {
    subject.type == .music ? 56 : 79
  }

  private var showsTypeBadge: Bool {
    switch subject.type {
    case .book, .music, .game:
      true
    default:
      false
    }
  }

  private var header: some View {
    HStack(alignment: .top, spacing: 12) {
      ImageView(img: subject.images?.resize(subjectImageQuality.smallSize))
        .imageStyle(width: 56, height: coverHeight, cornerRadius: theme.metrics.badgeRadius)
        .imageType(.subject)
        .imageBadge(show: subject.interest?.private ?? false) {
          Image(systemName: "lock")
        }
        .imageNavLink(subject.link)

      VStack(alignment: .leading, spacing: 3) {
        NavigationLink(value: NavDestination.subject(subject.id)) {
          HStack(alignment: .firstTextBaseline, spacing: 7) {
            Text(subject.title(with: titlePreference))
              .font(.subheadline.weight(.bold))
              .foregroundStyle(theme.cardTitle)
              .lineLimit(2)
              .multilineTextAlignment(.leading)
            if showsTypeBadge {
              GlassTypeBadge(type: subject.type)
            }
            Spacer(minLength: 0)
          }
        }
        .buttonStyle(.plain)

        ProgressSecondLineView(subject: subject, lineLimit: 2)
      }
      .frame(maxWidth: .infinity, alignment: .leading)
    }
  }

  var body: some View {
    CardView(padding: theme.metrics.cardPadding) {
      VStack(alignment: .leading, spacing: 12) {
        header

        switch subject.type {
        case .anime, .real:
          GlassProgressEpisodeSection(
            payload: payload,
            interactionMode: interactionMode,
            reload: reload
          )
        case .book:
          GlassProgressBookSection(subject: subject, reload: reload)
        default:
          EmptyView()
        }
      }
      .frame(maxWidth: .infinity, alignment: .leading)
    }
  }
}

private struct GlassProgressEpisodeSection: View {
  let payload: ProgressSubjectRenderPayload
  let interactionMode: EpisodeGridInteractionMode
  let reload: () async -> Void

  @Environment(\.theme) private var theme

  @State private var scrub: ProgressTickScrubState?
  @State private var updating: Bool = false
  @State private var loadingEpisodes: Bool = false
  @State private var showCollectionBox: Bool = false

  private var subject: SubjectDTO {
    payload.item.subject
  }

  private var episodes: [EpisodeDTO] {
    payload.item.episodes
  }

  private var nextEpisode: EpisodeDTO? {
    episodes.first(where: { $0.collectionTypeEnum == .none })
  }

  private var progressText: String {
    "\(subject.interest?.epStatus ?? 0)/\(subject.eps)"
  }

  private func loadEpisodes() {
    guard !loadingEpisodes else { return }
    Task {
      loadingEpisodes = true
      defer { loadingEpisodes = false }
      do {
        try await EpisodeRepository.loadEpisodes(subject.id)
        await reload()
      } catch {
        Notifier.shared.alert(error: error)
      }
    }
  }

  private func markWatched(_ episode: EpisodeDTO) {
    guard !updating else { return }
    Task {
      updating = true
      defer { updating = false }
      do {
        try await EpisodeRepository.updateEpisodeCollection(
          episodeId: episode.id, type: .collect)
        await reload()
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
      } catch {
        Notifier.shared.alert(error: error)
      }
    }
  }

  private func commitScrub(_ episode: EpisodeDTO, _ commit: ProgressTickCommit) async -> Bool {
    do {
      switch commit {
      case .watchUntil:
        try await EpisodeRepository.updateEpisodeCollection(
          episodeId: episode.id, type: .collect, batch: true)
      case .status(let type):
        try await EpisodeRepository.updateEpisodeCollection(
          episodeId: episode.id, type: type)
      }
      await reload()
      return true
    } catch {
      Notifier.shared.alert(error: error)
      return false
    }
  }

  private func airCaption(_ episode: EpisodeDTO) -> String {
    let number = episode.sort.progressEpisodeNumber
    let wait = episode.waitDesc
    if wait == "未知" {
      return "第 \(number) 话 · 待播出"
    }
    return "第 \(number) 话 · \(wait)播出"
  }

  @ViewBuilder
  private var primaryAction: some View {
    if let episode = nextEpisode {
      Button {
        markWatched(episode)
      } label: {
        GlassFillButton(kind: episode.aired ? .accent : .muted) {
          HStack(spacing: 6) {
            Image(systemName: episode.aired ? "checkmark" : "clock")
            Text(
              episode.aired
                ? "第 \(episode.sort.progressEpisodeNumber) 话 看过"
                : airCaption(episode)
            )
            .lineLimit(1)
          }
        }
        .opacity(updating ? 0.4 : 1)
        .overlay {
          if updating {
            ProgressView()
          }
        }
      }
      .buttonStyle(.plain)
      .disabled(!episode.aired || updating)
    } else {
      Button {
        showCollectionBox = true
      } label: {
        GlassFillButton(kind: .complete) {
          HStack(spacing: 6) {
            Image(systemName: "checkmark")
            Text("已看完 \(progressText) · 进度总览")
              .lineLimit(1)
          }
        }
      }
      .buttonStyle(.plain)
      .sheet(isPresented: $showCollectionBox) {
        SubjectCollectionBoxView(subjectId: subject.id, initialSubject: subject)
          .onDisappear {
            Task {
              await reload()
            }
          }
      }
    }
  }

  private func previewHint(_ state: ProgressTickScrubState) -> String {
    if state.canCommit {
      return "松手标记「看到 第 \(state.target.sort.progressEpisodeNumber) 话」 · 上滑取消"
    }
    if !state.target.aired {
      return "未播出 · 不可提交 · 上滑取消"
    }
    return "已看到这里 · 松手不做更改"
  }

  private func railKind(_ action: ProgressTickAction) -> GlassFillKind {
    switch action {
    case .cancel, .status(.dropped):
      .cancel
    case .status:
      .accent
    case .discuss:
      .glass
    }
  }

  private func railHint(_ action: ProgressTickAction, _ state: ProgressTickScrubState) -> String {
    let number = state.target.sort.progressEpisodeNumber
    switch action {
    case .cancel:
      return "松开取消 · 保持 第 \(state.restore.sort.progressEpisodeNumber) 话"
    case .status(let type):
      return "松开 · 第 \(number) 话 \(type.action)"
    case .discuss:
      return "松开 · 打开 第 \(number) 话 讨论"
    }
  }

  @ViewBuilder
  private func scrubHint(_ state: ProgressTickScrubState) -> some View {
    switch state.phase {
    case .preview:
      GlassFillButton(kind: state.canCommit ? .glass : .muted) {
        Text(previewHint(state))
          .lineLimit(1)
      }
    case .rail(let action):
      GlassFillButton(kind: railKind(action)) {
        HStack(spacing: 6) {
          Image(systemName: action.icon)
          Text(railHint(action, state))
            .lineLimit(1)
        }
      }
    }
  }

  private func handleScrubChange(_ state: ProgressTickScrubState?) {
    let phaseChanged = scrub?.phase != state?.phase || (scrub == nil) != (state == nil)
    if phaseChanged {
      withAnimation(.spring(response: 0.28, dampingFraction: 0.86)) {
        scrub = state
      }
    } else {
      scrub = state
    }
  }

  var body: some View {
    if episodes.isEmpty {
      Button(action: loadEpisodes) {
        GlassFillButton(kind: .glass) {
          Text(loadingEpisodes ? "加载中…" : "加载剧集")
        }
        .opacity(loadingEpisodes ? 0.6 : 1)
        .overlay {
          if loadingEpisodes {
            ProgressView()
          }
        }
      }
      .buttonStyle(.plain)
      .disabled(loadingEpisodes)
    } else {
      VStack(spacing: 11) {
        ProgressEpisodeTrackView(
          episodes: episodes,
          totalEpisodes: subject.eps,
          interactionMode: interactionMode,
          subjectCollectionType: subject.ctypeEnum,
          reload: reload,
          onScrubChange: handleScrubChange,
          onScrubCommit: commitScrub
        )

        HStack(spacing: 8) {
          if let scrub {
            scrubHint(scrub)
          } else {
            primaryAction
            NavigationLink(value: NavDestination.episodeList(subject.id)) {
              Text("剧集")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(theme.secondaryText)
                .padding(.horizontal, 14)
                .padding(.vertical, 9)
                .background {
                  RoundedRectangle(
                    cornerRadius: theme.metrics.controlRadius, style: .continuous
                  )
                  .fill(theme.controlFill)
                }
                .overlay {
                  RoundedRectangle(
                    cornerRadius: theme.metrics.controlRadius, style: .continuous
                  )
                  .strokeBorder(theme.controlBorder, lineWidth: 1)
                }
            }
            .buttonStyle(.plain)
          }
        }
      }
    }
  }
}

struct GlassProgressBookSection: View {
  let subject: SubjectDTO
  let reload: () async -> Void
  var compact: Bool = false

  @Environment(\.theme) private var theme

  @State private var updatingChapters: Bool = false
  @State private var updatingVolumes: Bool = false
  @State private var showEditor: Bool = false

  private var epStatus: Int {
    subject.interest?.epStatus ?? 0
  }

  private var volStatus: Int {
    subject.interest?.volStatus ?? 0
  }

  private func increment(chapters: Bool) {
    guard !updatingChapters, !updatingVolumes else { return }
    Task {
      if chapters {
        updatingChapters = true
      } else {
        updatingVolumes = true
      }
      defer {
        if chapters {
          updatingChapters = false
        } else {
          updatingVolumes = false
        }
      }
      do {
        try await SubjectRepository.updateSubjectProgress(
          subjectId: subject.id,
          eps: chapters ? epStatus + 1 : nil,
          vols: chapters ? nil : volStatus + 1
        )
        await reload()
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
      } catch {
        Notifier.shared.alert(error: error)
      }
    }
  }

  private var summary: some View {
    HStack(spacing: 4) {
      Text("读到")
      Text("\(epStatus)")
        .fontWeight(.bold)
        .foregroundStyle(theme.secondaryText)
      Text("/ \(subject.epsDesc) 话 ·")
      Text("\(volStatus)")
        .fontWeight(.bold)
        .foregroundStyle(theme.secondaryText)
      Text("/ \(subject.volumesDesc) 卷")
      Spacer(minLength: 0)
    }
    .font(.caption)
    .monospacedDigit()
    .foregroundStyle(theme.tertiaryText)
    .lineLimit(1)
  }

  private var chapterButton: some View {
    Button {
      increment(chapters: true)
    } label: {
      GlassFillButton(kind: .accent) {
        Text("章 +1")
      }
      .opacity(updatingChapters ? 0.4 : 1)
      .overlay {
        if updatingChapters {
          ProgressView()
        }
      }
    }
    .buttonStyle(.plain)
    .disabled(updatingChapters)
  }

  private var volumeButton: some View {
    Button {
      increment(chapters: false)
    } label: {
      GlassFillButton(kind: .glass) {
        Text("卷 +1")
      }
      .opacity(updatingVolumes ? 0.4 : 1)
      .overlay {
        if updatingVolumes {
          ProgressView()
        }
      }
    }
    .buttonStyle(.plain)
    .disabled(updatingVolumes)
  }

  var body: some View {
    VStack(alignment: .leading, spacing: compact ? 5 : 9) {
      if !compact {
        summary
      }
      if compact {
        chapterButton
        volumeButton
      } else {
        HStack(spacing: 7) {
          chapterButton
          volumeButton
          GlassGhostIconButton(systemImage: "square.and.pencil") {
            showEditor = true
          }
        }
      }
    }
    .sheet(isPresented: $showEditor) {
      GlassBookProgressEditorSheet(subject: subject, reload: reload)
    }
  }
}

struct GlassBookProgressEditorSheet: View {
  let subject: SubjectDTO
  let reload: () async -> Void

  @AppStorage("titlePreference") private var titlePreference: TitlePreference = .original

  @Environment(\.dismiss) private var dismiss

  @State private var eps: Int
  @State private var vols: Int
  @State private var updating = false

  private let initialEps: Int
  private let initialVols: Int

  init(subject: SubjectDTO, reload: @escaping () async -> Void) {
    let initialEps = subject.interest?.epStatus ?? 0
    let initialVols = subject.interest?.volStatus ?? 0

    self.subject = subject
    self.reload = reload
    self.initialEps = initialEps
    self.initialVols = initialVols
    _eps = State(initialValue: initialEps)
    _vols = State(initialValue: initialVols)
  }

  private var hasChanges: Bool {
    eps != initialEps || vols != initialVols
  }

  private func update() {
    guard hasChanges, !updating else { return }
    updating = true
    Task {
      defer { updating = false }
      do {
        try await SubjectRepository.updateSubjectProgress(
          subjectId: subject.id,
          eps: eps == initialEps ? nil : eps,
          vols: vols == initialVols ? nil : vols
        )
        await reload()
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        dismiss()
      } catch {
        Notifier.shared.alert(error: error)
      }
    }
  }

  var body: some View {
    SheetView(
      title: "更新阅读进度",
      size: .medium,
      closeDisabled: updating,
      applyFormStyle: true
    ) {
      Form {
        Section {
          Group {
            GlassBookProgressField(title: "话数", value: $eps, total: subject.epsDesc)
            GlassBookProgressField(title: "卷数", value: $vols, total: subject.volumesDesc)
          }
          .themedListRow()
        } header: {
          Text(subject.title(with: titlePreference))
            .font(.headline)
            .foregroundStyle(.primary)
            .textCase(nil)
            .lineLimit(2)
        }
      }
      .disabled(updating)
    } controls: {
      Button(action: update) {
        Text("更新")
          .opacity(updating ? 0 : 1)
          .overlay {
            if updating {
              ProgressView()
            }
          }
      }
      .disabled(!hasChanges || updating)
    }
  }
}

private struct GlassBookProgressField: View {
  let title: LocalizedStringKey
  @Binding var value: Int
  let total: String

  var body: some View {
    LabeledContent(title) {
      HStack {
        TextField("进度", value: $value, format: .number)
          .keyboardType(.numberPad)
          .multilineTextAlignment(.trailing)
          .monospacedDigit()
          .frame(minWidth: 48, maxWidth: 72)
          .textFieldStyle(.roundedBorder)

        Text("/ \(total)")
          .foregroundStyle(.secondary)
          .monospacedDigit()

        Stepper(value: $value, in: 0...Int.max) {
          EmptyView()
        }
        .labelsHidden()
      }
    }
  }
}
