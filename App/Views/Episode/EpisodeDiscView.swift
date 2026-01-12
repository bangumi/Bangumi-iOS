import Flow
import OSLog
import SwiftData
import SwiftUI

struct EpisodeDiscView: View {
  let subjectId: Int

  @State private var refreshed: Bool = false

  @Query private var episodes: [Episode]

  init(subjectId: Int) {
    self.subjectId = subjectId

    let descriptor = FetchDescriptor<Episode>(
      predicate: #Predicate<Episode> {
        $0.subjectId == subjectId
      }, sortBy: [SortDescriptor(\.disc), SortDescriptor(\.sort)])
    _episodes = Query(descriptor)
  }

  var discs: [Int: [Episode]] {
    var discs: [Int: [Episode]] = [:]
    for episode in episodes {
      discs[episode.disc, default: []].append(episode)
    }
    return discs
  }

  func refresh() {
    if refreshed { return }
    refreshed = true

    Task {
      do {
        try await Chii.shared.loadEpisodes(subjectId)
      } catch {
        Notifier.shared.alert(error: error)
      }
    }
  }

  func episodeLine(_ episode: Episode) -> AttributedString {
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
    }.animation(.default, value: episodes)
  }
}

#Preview {
  let container = mockContainer()

  let subject = Subject.previewMusic
  container.mainContext.insert(subject)

  let episodes = Episode.previewMusic
  for episode in episodes {
    container.mainContext.insert(episode)
  }

  return ScrollView {
    LazyVStack(alignment: .leading) {
      EpisodeDiscView(subjectId: subject.subjectId)
        .modelContainer(container)
    }
  }.padding()
}
