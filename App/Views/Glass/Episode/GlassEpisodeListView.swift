import SwiftUI

struct GlassEpisodeListView: View {
  let subjectId: Int

  @Environment(\.theme) private var theme

  @State private var refreshed: Bool = false
  @State private var reloadToken = 0
  @State private var countMain: Int = 0
  @State private var countOther: Int = 0

  @State private var main: Bool = true
  @State private var filterCollection: Bool = false
  @State private var sortDesc: Bool = false

  private func loadCounts() async {
    do {
      let db = try await AppContext.shared.getDB()
      let counts = try await db.fetchEpisodeCounts(subjectId: subjectId)
      countMain = counts.main
      countOther = counts.other
    } catch {
      Notifier.shared.alert(error: error)
    }
  }

  private func refresh() async {
    if refreshed { return }
    refreshed = true

    do {
      try await EpisodeRepository.loadEpisodes(subjectId)
      reloadToken += 1
    } catch {
      Notifier.shared.alert(error: error)
    }
  }

  private var controls: some View {
    HStack(spacing: 8) {
      GlassChip(title: "本篇", count: countMain, isSelected: main) {
        withAnimation(.default) {
          main = true
        }
      }
      GlassChip(title: "其他", count: countOther, isSelected: !main) {
        withAnimation(.default) {
          main = false
        }
      }
      Spacer(minLength: 0)
      GlassGhostIconButton(
        systemImage: filterCollection ? "eye.slash" : "eye"
      ) {
        withAnimation(.default) {
          filterCollection.toggle()
        }
      }
      .sensoryFeedback(.selection, trigger: filterCollection)
      GlassGhostIconButton(
        systemImage: sortDesc ? "arrow.down" : "arrow.up"
      ) {
        withAnimation(.default) {
          sortDesc.toggle()
        }
      }
      .sensoryFeedback(.selection, trigger: sortDesc)
    }
    .padding(.horizontal, theme.metrics.screenPadding)
  }

  var body: some View {
    VStack(spacing: theme.metrics.listSpacing) {
      controls
      GlassEpisodeListDetailView(
        subjectId: subjectId,
        sortDesc: sortDesc,
        main: main,
        filterCollection: filterCollection,
        reloadToken: reloadToken
      )
    }
    .navigationTitle("章节列表")
    .navigationBarTitleDisplayMode(.inline)
    .onAppear {
      Task {
        await loadCounts()
        await refresh()
        await loadCounts()
      }
    }
  }
}

private struct GlassEpisodeListDetailView: View {
  let subjectId: Int
  let sortDesc: Bool
  let main: Bool
  let filterCollection: Bool
  let reloadToken: Int

  @AppStorage("episodeGridInteractionMode") private var episodeGridInteractionMode:
    EpisodeGridInteractionMode = .menu

  @Environment(\.theme) private var theme

  @State private var episodes: [EpisodeDTO] = []
  @State private var subjectCollectionType: CollectionType = .none

  private func load() async {
    do {
      let db = try await AppContext.shared.getDB()
      let fetchedSubjectCollectionType =
        try await db.getSubjectDTO(subjectId)?.ctypeEnum ?? .none
      let fetchedEpisodes = try await db.fetchEpisodes(
        subjectId: subjectId,
        main: main,
        uncollectedOnly: filterCollection,
        sortDesc: sortDesc
      )
      withAnimation(.default) {
        subjectCollectionType = fetchedSubjectCollectionType
        episodes = fetchedEpisodes
      }
    } catch {
      Notifier.shared.alert(error: error)
    }
  }

  var body: some View {
    ScrollView {
      LazyVStack(spacing: theme.metrics.listSpacing) {
        if episodes.isEmpty {
          GlassEmptyCard(
            systemImage: "rectangle.stack",
            title: "没有章节",
            description: "换个筛选条件，或稍后再试"
          )
        }
        ForEach(episodes) { episode in
          CardView(padding: theme.metrics.cardPadding) {
            GlassEpisodeRowView(
              episode: episode,
              interactionMode: episodeGridInteractionMode,
              subjectCollectionType: subjectCollectionType,
              reload: load
            )
          }
        }
      }
      .padding(.horizontal, theme.metrics.screenPadding)
      .padding(.bottom, theme.metrics.screenPadding)
    }
    .task(id: "\(subjectId)-\(sortDesc)-\(main)-\(filterCollection)-\(reloadToken)") {
      await load()
    }
  }
}

private struct GlassEpisodeRowView: View {
  let episode: EpisodeDTO
  let interactionMode: EpisodeGridInteractionMode
  let subjectCollectionType: CollectionType
  let reload: () async -> Void

  @AppStorage("isolationMode") private var isolationMode: Bool = false
  @AppStorage("isAuthenticated") private var isAuthenticated: Bool = false
  @AppStorage("titlePreference") private var titlePreference: TitlePreference = .original

  @Environment(\.theme) private var theme

  private var airCaption: String {
    episode.aired ? "已播" : "未播"
  }

  var body: some View {
    HStack(alignment: .top, spacing: 10) {
      ProgressEpisodeChip(
        episode: episode,
        kind: ProgressEpisodeTickKind(episode: episode, isNext: false),
        size: 34,
        cornerRadius: theme.metrics.cellRadius,
        interactionMode: interactionMode,
        subjectCollectionType: subjectCollectionType,
        reload: reload
      )

      VStack(alignment: .leading, spacing: 5) {
        NavigationLink(value: NavDestination.episode(episode.id)) {
          Text(episode.title(with: titlePreference))
            .font(.subheadline.weight(.bold))
            .foregroundStyle(theme.cardTitle)
            .lineLimit(2)
            .multilineTextAlignment(.leading)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .buttonStyle(.plain)

        HStack(spacing: 8) {
          if episode.typeEnum == .main {
            Text(airCaption)
          } else {
            Text(episode.typeEnum.description)
          }
          if !episode.duration.isEmpty {
            Label(episode.duration, systemImage: "clock")
          }
          if !episode.airdate.isEmpty {
            Label(episode.airdate, systemImage: "calendar")
          }
          Spacer(minLength: 0)
          if !isolationMode {
            Label("+\(episode.comment)", systemImage: "bubble")
          }
        }
        .font(.caption)
        .monospacedDigit()
        .foregroundStyle(theme.tertiaryText)
        .lineLimit(1)

        if isAuthenticated, episode.collectionTypeEnum != .none, episode.collectedAt > 0 {
          Text("\(episode.collectionTypeEnum.description): \(episode.collectedAt.datetimeDisplay)")
            .font(.caption2)
            .foregroundStyle(theme.secondaryText)
            .lineLimit(1)
        }
      }
    }
    .frame(maxWidth: .infinity, alignment: .leading)
  }
}
