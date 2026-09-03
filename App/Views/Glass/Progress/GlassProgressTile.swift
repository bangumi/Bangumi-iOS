import SwiftUI

struct GlassProgressTile: View {
  let payload: ProgressSubjectRenderPayload
  let interactionMode: EpisodeGridInteractionMode
  let reload: () async -> Void

  @AppStorage("subjectImageQuality") private var subjectImageQuality: ImageQuality = .high
  @AppStorage("titlePreference") private var titlePreference: TitlePreference = .original

  @Environment(\.theme) private var theme

  @State private var updating: Bool = false
  @State private var loadingEpisodes: Bool = false
  @State private var autoSyncRequested: Bool = false
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

  private var epStatus: Int {
    subject.interest?.epStatus ?? 0
  }

  private var isFinished: Bool {
    subject.eps > 0 && epStatus >= subject.eps
  }

  private var progressBadgeText: String {
    if isFinished {
      return "✓ \(subject.eps)"
    }
    return "\(epStatus)/\(subject.eps > 0 ? "\(subject.eps)" : "??")"
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

  private var needsEpisodeSync: Bool {
    GlassProgressEpisodeSync.needsSync(subject: subject, episodes: episodes)
  }

  private func loadEpisodes() {
    guard !loadingEpisodes else { return }
    Task {
      loadingEpisodes = true
      defer { loadingEpisodes = false }
      do {
        try await EpisodeRepository.loadEpisodes(subject.id)
        GlassProgressEpisodeSync.synced.insert(subject.id)
        await reload()
      } catch {
        Notifier.shared.alert(error: error)
      }
    }
  }

  private var progressBadge: some View {
    Text(progressBadgeText)
      .font(.caption2.weight(.bold))
      .monospaced()
      .foregroundStyle(.white)
      .padding(.horizontal, 8)
      .padding(.vertical, 3)
      .background {
        Capsule()
          .fill(isFinished ? theme.success.opacity(0.85) : theme.maskFill)
      }
      .padding(6)
  }

  private var cover: some View {
    Color.clear
      .aspectRatio(3 / 4.2, contentMode: .fit)
      .overlay {
        ImageView(img: subject.images?.resize(subjectImageQuality.mediumSize))
          .imageType(.subject)
          .imageStyle(cornerRadius: theme.metrics.coverRadius, contentMode: .fill)
          .imageBadge(show: subject.interest?.private ?? false) {
            Image(systemName: "lock")
          }
          .imageNavLink(subject.link)
      }
      .overlay(alignment: .bottomLeading) {
        progressBadge
          .allowsHitTesting(false)
      }
  }

  @ViewBuilder
  private var cells: some View {
    if needsEpisodeSync {
      HStack(spacing: 3) {
        ForEach(0..<5, id: \.self) { _ in
          RoundedRectangle(cornerRadius: theme.metrics.cellRadius / 2, style: .continuous)
            .fill(theme.track)
            .frame(maxWidth: .infinity)
            .frame(height: 18)
        }
      }
    } else {
      HStack(spacing: 3) {
        ForEach(episodes) { episode in
          ProgressEpisodeChip(
            episode: episode,
            kind: ProgressEpisodeTickKind(
              episode: episode, isNext: episode.id == nextEpisode?.id),
            size: 18,
            cornerRadius: theme.metrics.cellRadius / 2,
            interactionMode: interactionMode,
            subjectCollectionType: subject.ctypeEnum,
            reload: reload
          )
        }
        Spacer(minLength: 0)
      }
    }
  }

  @ViewBuilder
  private var action: some View {
    if needsEpisodeSync {
      Button(action: loadEpisodes) {
        GlassFillButton(kind: .glass) {
          Text(loadingEpisodes ? "同步中…" : "↓ 同步")
            .lineLimit(1)
        }
      }
      .buttonStyle(.plain)
      .disabled(loadingEpisodes)
      .task(id: subject.id) {
        guard !autoSyncRequested else { return }
        autoSyncRequested = true
        loadEpisodes()
      }
    } else if let episode = nextEpisode {
      Button {
        markWatched(episode)
      } label: {
        GlassFillButton(kind: episode.aired ? .accent : .muted) {
          Text(
            episode.aired
              ? "✓ \(episode.sort.progressEpisodeNumber)"
              : "◷ \(episode.waitDesc)"
          )
          .lineLimit(1)
        }
        .opacity(updating ? 0.4 : 1)
      }
      .buttonStyle(.plain)
      .disabled(!episode.aired || updating)
    } else {
      Button {
        showCollectionBox = true
      } label: {
        GlassFillButton(kind: .complete) {
          Text("已看完")
            .lineLimit(1)
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

  @ViewBuilder
  private var typeAction: some View {
    switch subject.type {
    case .anime, .real:
      VStack(spacing: 5) {
        cells
        action
      }
    case .book:
      GlassProgressBookSection(subject: subject, reload: reload, compact: true)
    default:
      GlassTypeBadge(type: subject.type)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 5) {
      cover
      typeAction
      VStack(alignment: .leading, spacing: 2) {
        NavigationLink(value: NavDestination.subject(subject.id)) {
          Text(subject.title(with: titlePreference))
            .font(.caption.weight(.bold))
            .foregroundStyle(theme.cardTitle)
            .lineLimit(1)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .buttonStyle(.plain)
        ProgressSecondLineView(subject: subject)
      }
    }
  }
}
