import Flow
import OSLog
import SwiftUI

struct EpisodeDiscView: View {
  let subjectId: Int

  @State private var refreshed: Bool = false
  @State private var episodes: [EpisodeDTO] = []

  var discs: [Int: [EpisodeDTO]] {
    var discs: [Int: [EpisodeDTO]] = [:]
    for episode in episodes {
      discs[episode.disc, default: []].append(episode)
    }
    return discs
  }

  private func loadCached() async {
    do {
      let db = try await AppContext.shared.getDB()
      episodes = try await db.fetchDiscEpisodes(subjectId: subjectId)
    } catch {
      Logger.app.error("Failed to load cached disc episodes: \(error)")
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

  func episodeLine(_ episode: EpisodeDTO) -> AttributedString {
    var line = "\(Int(episode.sort)) \(episode.name)".withLink(episode.link)
    line.font = .footnote
    if !episode.nameCN.isEmpty {
      var subline = AttributedString(" / \(episode.nameCN)")
      subline.font = .caption
      subline.foregroundColor = .secondary
      line += subline
    }
    return line
  }

  var body: some View {
    VStack(spacing: 2) {
      HStack(alignment: .bottom) {
        Text("曲目列表:")
          .foregroundStyle(episodes.count > 0 ? .primary : .secondary)
          .font(.title3)
          .onAppear(perform: refresh)
        Spacer()
      }
      Divider()
    }.padding(.top, 5)
    VStack(alignment: .leading) {
      ForEach(Array(discs.keys.sorted()), id: \.self) { disc in
        Text("Disc \(disc)")
          .foregroundStyle(.secondary)
          .padding(.top, 5)
        Divider()
        ForEach(discs[disc] ?? []) { episode in
          Text(episodeLine(episode)).lineLimit(1)
          Divider()
        }
      }
    }.task {
      await loadCached()
      refresh()
    }
  }
}
