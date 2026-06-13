import OSLog
import SwiftUI

struct EpisodeListView: View {
  let subjectId: Int

  @State private var refreshed: Bool = false
  @State private var reloadToken = 0
  @State private var countMain: Int = 0
  @State private var countOther: Int = 0

  @State private var main: Bool = true
  @State private var filterCollection: Bool = false
  @State private var sortDesc: Bool = false

  func loadCounts() async {
    do {
      let db = try await AppContext.shared.getDB()
      let counts = try await db.fetchEpisodeCounts(subjectId: subjectId)
      countMain = counts.main
      countOther = counts.other
    } catch {
      Notifier.shared.alert(error: error)
    }
  }

  func refresh() async {
    if refreshed { return }
    refreshed = true

    do {
      try await EpisodeRepository.loadEpisodes(subjectId)
      reloadToken += 1
    } catch {
      Notifier.shared.alert(error: error)
    }
  }

  var body: some View {
    HStack {
      Image(systemName: filterCollection ? "eye.slash.circle.fill" : "eye.circle.fill")
        .foregroundStyle(filterCollection ? .accent : .secondary)
        .font(.title)
        .sensoryFeedback(.selection, trigger: filterCollection)
        .onTapGesture {
          self.filterCollection.toggle()
        }
      Spacer()
      Picker("Episode Type", selection: $main) {
        Text("本篇(\(countMain))").tag(true)
        Text("其他(\(countOther))").tag(false)
      }
      .pickerStyle(.segmented)
      Spacer()
      Image(systemName: sortDesc ? "arrow.down.circle.fill" : "arrow.up.circle.fill")
        .foregroundStyle(sortDesc ? .accent : .secondary)
        .font(.title)
        .sensoryFeedback(.selection, trigger: sortDesc)
        .onTapGesture {
          self.sortDesc.toggle()
        }
    }.padding(.horizontal, 8)
    EpisodeListDetailView(
      subjectId: subjectId, sortDesc: sortDesc,
      main: main, filterCollection: filterCollection,
      reloadToken: reloadToken
    )
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

struct EpisodeListDetailView: View {
  let subjectId: Int
  let sortDesc: Bool
  let main: Bool
  let filterCollection: Bool
  let reloadToken: Int

  @State private var episodes: [EpisodeDTO] = []

  private func load() async {
    do {
      let db = try await AppContext.shared.getDB()
      episodes = try await db.fetchEpisodes(
        subjectId: subjectId,
        main: main,
        uncollectedOnly: filterCollection,
        sortDesc: sortDesc
      )
    } catch {
      Notifier.shared.alert(error: error)
    }
  }

  var body: some View {
    ScrollView {
      LazyVStack(spacing: 10) {
        ForEach(episodes) { item in
          EpisodeRowView(episode: item) {
            await load()
          }
        }
      }.padding(.horizontal, 8)
    }
    .task(id: "\(subjectId)-\(sortDesc)-\(main)-\(filterCollection)-\(reloadToken)") {
      await load()
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

  return EpisodeListView(subjectId: subject.subjectId)
    .modelContainer(container)
}
