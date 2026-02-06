import SwiftData
import SwiftUI

struct EpisodeView: View {
  let episodeId: Int

  @AppStorage("shareDomain") var shareDomain: ShareDomain = .chii
  @AppStorage("isolationMode") var isolationMode: Bool = false
  @AppStorage("isAuthenticated") var isAuthenticated: Bool = false

  @Environment(\.dismiss) private var dismiss

  @Query private var episodes: [Episode]
  private var episode: Episode? { episodes.first }

  @State private var comments: [CommentDTO] = []
  @State private var loadingComments: Bool = false
  @State private var showCommentBox: Bool = false
  @State private var showIndexPicker: Bool = false

  init(episodeId: Int) {
    self.episodeId = episodeId

    _episodes = Query(filter: #Predicate<Episode> { $0.episodeId == episodeId })
  }

  func load() async {
    do {
      try await Chii.shared.loadEpisode(episodeId)
      if !isolationMode {
        loadingComments = true
        comments = try await Chii.shared.getEpisodeComments(episodeId)
        loadingComments = false
      }
    } catch let error as ChiiError {
      switch error {
      case .notFound:
        // 404 错误，删除当前 episode
        try? await Chii.shared.deleteEpisode(episodeId)
        dismiss()
      default:
        Notifier.shared.alert(error: error)
      }
    } catch {
      Notifier.shared.alert(error: error)
    }
  }

  var shareLink: URL {
    URL(string: "\(shareDomain.url)/ep/\(episodeId)")!
  }

  var body: some View {
    ScrollView {
      VStack(alignment: .leading) {
        if let episode = episode {
          if let subject = episode.subject {
            SubjectTinyView(subject: subject.slim)
              .padding(.vertical, 8)
          }
          EpisodeInfoView(episode: episode)
        }
        Divider()
        if let desc = episode?.desc, !desc.isEmpty {
          Text(desc).foregroundStyle(.secondary)
          Divider()
        }
        if !isolationMode {
          VStack(alignment: .leading, spacing: 2) {
            HStack {
              Text("吐槽箱").font(.title3)
              if loadingComments {
                ProgressView()
                  .controlSize(.small)
              }
            }
            Divider()
          }
          LazyVStack(alignment: .leading, spacing: 8) {
            ForEach(Array(zip(comments.indices, comments)), id: \.1) { idx, comment in
              CommentItemView(type: .episode(episodeId), comment: comment, idx: idx)
              if comment.id != comments.last?.id {
                Divider()
              }
            }
          }
        }
        Spacer()
      }.padding(.horizontal, 8)
    }
    .refreshable {
      Task {
        await load()
      }
    }
    .task(load)
    .animation(.default, value: comments)
    .navigationTitle("章节详情")
    .navigationBarTitleDisplayMode(.inline)
    .toolbar {
      ToolbarItem(placement: .topBarTrailing) {
        Menu {
          Button {
            showCommentBox = true
          } label: {
            Label("吐槽", systemImage: "plus.bubble")
          }
          .disabled(!isAuthenticated)
          Divider()
          Button {
            showIndexPicker = true
          } label: {
            Label("收藏", systemImage: "book")
          }
          .disabled(!isAuthenticated)
          ShareLink(item: shareLink) {
            Label("分享", systemImage: "square.and.arrow.up")
          }
        } label: {
          Image(systemName: "ellipsis")
        }
      }
    }
    .sheet(isPresented: $showCommentBox) {
      CreateCommentBoxSheet(type: .episode(episodeId)) {
        Task { await load() }
      }
    }
    .sheet(isPresented: $showIndexPicker) {
      IndexPickerSheet(
        category: .episode,
        itemId: episodeId,
        itemTitle: "章节详情"
      )
    }
    .handoff(url: shareLink, title: "章节详情")
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
