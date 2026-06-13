import Flow
import OSLog
import SwiftUI

struct EpisodeGridView: View {
  let subjectId: Int

  @AppStorage("isolationMode") var isolationMode: Bool = false
  @AppStorage("isAuthenticated") var isAuthenticated: Bool = false
  @AppStorage("episodeGridInteractionMode") var episodeGridInteractionMode:
    EpisodeGridInteractionMode = .menu

  @State private var refreshed: Bool = false
  @State private var episodeMains: [EpisodeDTO] = []
  @State private var episodeSps: [EpisodeDTO] = []

  private func loadCached() async {
    do {
      let db = try await AppContext.shared.getDB()
      episodeMains = try await db.fetchEpisodes(subjectId: subjectId, main: true, limit: 50)
      episodeSps = Array(
        try await db.fetchEpisodes(subjectId: subjectId)
          .filter { $0.type == .sp }
          .prefix(10)
      )
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
    HFlow(alignment: .center, spacing: 2) {
      ForEach(episodeMains) { episode in
        EpisodeItemView(episode: episode, interactionMode: episodeGridInteractionMode) {
          await loadCached()
        }
      }
      if !episodeSps.isEmpty {
        Text("SP")
          .foregroundStyle(.leadingBorder)
          .padding(.vertical, 3)
          .padding(.leading, 5)
          .padding(.trailing, 1)
          .overlay(
            RoundedRectangle(cornerRadius: 4)
              .frame(width: 4)
              .foregroundStyle(.leadingBorder)
              .offset(x: -12, y: 0)
          )
          .padding(2)
          .bold()
        ForEach(episodeSps) { episode in
          EpisodeItemView(episode: episode, interactionMode: episodeGridInteractionMode) {
            await loadCached()
          }
        }
      }
    }
    .padding(.leading, 10)
    .overlay(
      HStack {
        RoundedRectangle(cornerRadius: 4)
          .frame(width: 4)
          .foregroundStyle(.leadingBorder)
          .offset(x: 0, y: 0)
        Spacer()
      }
    )
    .task {
      await loadCached()
      refresh()
    }
  }
}

#Preview {
  let container = mockContainer()

  let subject = Subject.previewAnime
  container.mainContext.insert(subject)

  let episodes = Episode.previewAnime
  for episode in episodes {
    container.mainContext.insert(episode)
  }

  return ScrollView {
    LazyVStack(alignment: .leading) {
      EpisodeGridView(subjectId: subject.subjectId)
        .modelContainer(container)
    }
  }.padding()
}
