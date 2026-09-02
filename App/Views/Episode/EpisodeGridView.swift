import Flow
import OSLog
import SwiftUI

struct EpisodeGridView: View {
  let subjectId: Int
  let subjectCollectionType: CollectionType

  @AppStorage("isolationMode") var isolationMode: Bool = false
  @AppStorage("isAuthenticated") var isAuthenticated: Bool = false
  @AppStorage("episodeGridInteractionMode") var episodeGridInteractionMode:
    EpisodeGridInteractionMode = .menu

  @Environment(\.theme) private var theme

  @State private var refreshed: Bool = false
  @State private var episodeMains: [EpisodeDTO] = []
  @State private var episodeSps: [EpisodeDTO] = []

  private var nextMainId: Int? {
    episodeMains.first(where: { $0.collectionTypeEnum == .none })?.id
  }

  private var leadingBorderColor: Color {
    theme.isClassic ? .leadingBorder : .clear
  }

  private func loadCached() async {
    do {
      let db = try await AppContext.shared.getDB()
      let fetchedEpisodeMains = try await db.fetchEpisodes(subjectId: subjectId, main: true, limit: 50)
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

  func refresh() {
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

  var body: some View {
    VStack(spacing: 2) {
      HStack(alignment: .bottom) {
        if isAuthenticated {
          Text("观看进度管理:")
        } else {
          Text("章节列表:")
        }
        Spacer()
        NavigationLink(value: NavDestination.episodeList(subjectId)) {
          Text("全部章节 »").font(.caption)
        }.buttonStyle(.navigation)
      }.onAppear(perform: refresh)
      Divider()
    }.padding(.top, 5)
    Group {
      if theme.isClassic {
        episodeFlow
      } else {
        CardView(padding: theme.metrics.cardPadding) {
          episodeFlow
        }
      }
    }
    .task {
      await loadCached()
      refresh()
    }
  }

  private func episodeItem(_ episode: EpisodeDTO, isNext: Bool) -> some View {
    EpisodeItemView(
      episode: episode,
      interactionMode: episodeGridInteractionMode,
      subjectCollectionType: subjectCollectionType,
      isNext: isNext
    ) {
      await loadCached()
    }
  }

  private var episodeFlow: some View {
    let nextId = theme.isClassic ? nil : nextMainId
    return HFlow(alignment: .center, spacing: theme.isClassic ? 2 : 6) {
      ForEach(episodeMains) { episode in
        episodeItem(episode, isNext: episode.id == nextId)
      }
      if !episodeSps.isEmpty {
        Text("SP")
          .foregroundStyle(theme.isClassic ? .leadingBorder : theme.tertiaryText)
          .padding(.vertical, 3)
          .padding(.leading, 5)
          .padding(.trailing, 1)
          .overlay(
            RoundedRectangle(cornerRadius: 4)
              .frame(width: 4)
              .foregroundStyle(leadingBorderColor)
              .offset(x: -12, y: 0)
          )
          .padding(2)
          .bold()
        ForEach(episodeSps) { episode in
          episodeItem(episode, isNext: false)
        }
      }
    }
    .padding(.leading, 10)
    .overlay(
      HStack {
        RoundedRectangle(cornerRadius: 4)
          .frame(width: 4)
          .foregroundStyle(leadingBorderColor)
          .offset(x: 0, y: 0)
        Spacer()
      }
    )
  }
}
