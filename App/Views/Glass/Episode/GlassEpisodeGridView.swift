import Flow
import OSLog
import SwiftUI

struct GlassEpisodeGridView: View {
  let subjectId: Int
  let subjectCollectionType: CollectionType

  @AppStorage("isAuthenticated") var isAuthenticated: Bool = false
  @AppStorage("episodeGridInteractionMode") var episodeGridInteractionMode:
    EpisodeGridInteractionMode = .menu

  @Environment(\.theme) private var theme

  @State private var refreshed: Bool = false
  @State private var episodeMains: [EpisodeDTO] = []
  @State private var episodeSps: [EpisodeDTO] = []

  private func loadCached() async {
    do {
      let db = try await AppContext.shared.getDB()
      let fetchedEpisodeMains = try await db.fetchEpisodes(
        subjectId: subjectId, main: true, limit: 50)
      let fetchedEpisodeSps = Array(
        try await db.fetchEpisodes(subjectId: subjectId)
          .filter { $0.type == .sp }
          .prefix(10)
      )
      withAnimation(.default) {
        episodeMains = fetchedEpisodeMains
        episodeSps = fetchedEpisodeSps
      }
    } catch {
      Logger.app.error("Failed to load cached episodes: \(error)")
    }
  }

  private func refresh() {
    if refreshed { return }
    refreshed = true

    Task {
      do {
        try await EpisodeRepository.loadEpisodes(subjectId)
        await loadCached()
      } catch {
        Notifier.shared.alert(error: error)
      }
    }
  }

  private var nextMainId: Int? {
    episodeMains.first(where: { $0.collectionTypeEnum == .none })?.id
  }

  private func chip(_ episode: EpisodeDTO, isNext: Bool) -> some View {
    ProgressEpisodeChip(
      episode: episode,
      kind: ProgressEpisodeTickKind(episode: episode, isNext: isNext),
      size: 34,
      cornerRadius: theme.metrics.cellRadius,
      interactionMode: episodeGridInteractionMode,
      subjectCollectionType: subjectCollectionType,
      reload: { await loadCached() }
    )
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 10) {
      ThemedSectionHeader(isAuthenticated ? "观看进度管理:" : "章节列表:") {
        NavigationLink(value: NavDestination.episodeList(subjectId)) {
          GlassMoreLabel(title: "全部章节 »")
        }
        .buttonStyle(.plain)
      }
      .onAppear(perform: refresh)

      CardView(padding: theme.metrics.cardPadding) {
        VStack(alignment: .leading, spacing: 10) {
          HFlow(alignment: .center, spacing: 6) {
            ForEach(episodeMains) { episode in
              chip(episode, isNext: episode.id == nextMainId)
            }
          }

          if !episodeSps.isEmpty {
            HStack(alignment: .center, spacing: 6) {
              Text(verbatim: "SP")
                .font(.caption2.weight(.heavy))
                .monospaced()
                .foregroundStyle(theme.tertiaryText)
              Rectangle()
                .fill(theme.separator)
                .frame(width: 1, height: 22)
              HFlow(alignment: .center, spacing: 6) {
                ForEach(episodeSps) { episode in
                  chip(episode, isNext: false)
                }
              }
            }
          }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
      }
    }
    .task {
      await loadCached()
      refresh()
    }
  }
}
