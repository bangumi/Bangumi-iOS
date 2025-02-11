import SwiftData
import SwiftUI

struct EpisodeView: View {
  let episodeId: Int

  @AppStorage("shareDomain") var shareDomain: ShareDomain = .chii
  @AppStorage("isolationMode") var isolationMode: Bool = false

  @Query private var episodes: [Episode]
  private var episode: Episode? { episodes.first }

  @State private var comments: [CommentDTO] = []

  init(episodeId: Int) {
    self.episodeId = episodeId

    _episodes = Query(filter: #Predicate<Episode> { $0.episodeId == episodeId })
  }

  func load() async {
    do {
      try await Chii.shared.loadEpisode(episodeId)
      if !isolationMode {
        comments = try await Chii.shared.getEpisodeComments(episodeId)
      }
    } catch {
      Notifier.shared.alert(error: error)
    }
  }

  var shareLink: URL {
    URL(string: "https://\(shareDomain.rawValue)/ep/\(episodeId)")!
  }

  var body: some View {
    ScrollView {
      LazyVStack(alignment: .leading) {
        if let episode = episode {
          if let subject = episode.subject {
            SubjectTinyView(subject: subject.slim)
              .padding(.vertical, 8)
          }
          EpisodeInfoView().environment(episode)
        }
        Divider()
        if let desc = episode?.desc, !desc.isEmpty {
          Text(desc).foregroundStyle(.secondary)
          Divider()
        }
        if !isolationMode {
          Text("吐槽箱").font(.title3)
          Divider()
          ForEach(comments) { comment in
            CommentItemView(comment: comment)
          }
        }
        Spacer()
      }.padding(.horizontal, 8)
    }
    .task(load)
    .animation(.default, value: comments)
    .navigationTitle("章节详情")
    .navigationBarTitleDisplayMode(.inline)
    .toolbar {
      ToolbarItem(placement: .topBarTrailing) {
        Menu {
          ShareLink(item: shareLink) {
            Label("分享", systemImage: "square.and.arrow.up")
          }
        } label: {
          Image(systemName: "ellipsis.circle")
        }
      }
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

  return EpisodeView(episodeId: episodes.first!.episodeId)
    .modelContainer(container)
}
