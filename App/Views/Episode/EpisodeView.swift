import SwiftUI

struct EpisodeView: View {
  let episodeId: Int
  let initialPostID: Int?

  @AppStorage("shareDomain") var shareDomain: ShareDomain = .chii
  @AppStorage("isolationMode") var isolationMode: Bool = false
  @AppStorage("isAuthenticated") var isAuthenticated: Bool = false
  @AppStorage("profile") var profile: Profile = Profile()

  @Environment(\.dismiss) private var dismiss

  @State private var episode: EpisodeDTO?
  @State private var episodeLoadFailed: Bool = false
  @State private var isLoadingEpisode: Bool = false
  @State private var needsEpisodeReload: Bool = false
  @State private var showCommentBox: Bool = false
  @State private var showIndexPicker: Bool = false
  @State private var showWikiEdit: Bool = false

  init(episodeId: Int, initialPostID: Int? = nil) {
    self.episodeId = episodeId
    self.initialPostID = initialPostID
  }

  private func loadCached() async {
    do {
      let db = try await AppContext.shared.getDB()
      let cachedEpisode = try await db.getEpisodeDTO(episodeId)
      withAnimation(.default) {
        episode = cachedEpisode
        episodeLoadFailed = false
      }
    } catch {
      Notifier.shared.alert(error: error)
    }
  }

  func load() async {
    if isLoadingEpisode {
      needsEpisodeReload = true
      return
    }
    isLoadingEpisode = true
    defer {
      isLoadingEpisode = false
    }

    repeat {
      needsEpisodeReload = false
      guard await loadOnce() else {
        return
      }
    } while needsEpisodeReload
  }

  private func loadOnce() async -> Bool {
    if episode == nil {
      episodeLoadFailed = false
    }

    do {
      try await EpisodeRepository.loadEpisode(episodeId)
      await loadCached()
    } catch let error as ChiiError {
      switch error {
      case .notFound:
        // Remove stale local data when the episode no longer exists.
        try? await EpisodeRepository.deleteEpisode(episodeId)
        dismiss()
        return false
      default:
        if episode == nil {
          episodeLoadFailed = true
        }
        Notifier.shared.alert(error: error)
      }
    } catch {
      if episode == nil {
        episodeLoadFailed = true
      }
      Notifier.shared.alert(error: error)
    }
    return true
  }

  var shareLink: URL {
    URL(string: "\(shareDomain.url)/ep/\(episodeId)")!
  }

  var body: some View {
    CommentListView(
      route: CommentListRoute(
        parent: .episode(episodeId),
        initialPostID: initialPostID
      ),
      episode: episode,
      episodeLoadFailed: episodeLoadFailed,
      presentsNewComment: $showCommentBox,
      onParentRefresh: {
        await load()
      }
    )
    .task {
      await loadCached()
      await load()
    }
    .toolbar {
      ToolbarItemGroup(placement: .topBarTrailing) {
        Button {
          showCommentBox = true
        } label: {
          Label {
            Text("添加吐槽")
          } icon: {
            ToolbarCircle {
              Image(systemName: "plus.bubble")
            }
          }
        }
        .disabled(episode == nil || !isAuthenticated || isolationMode)

        Menu {
          if isAuthenticated && profile.groupEnum.canEditEpisodeWiki {
            Button {
              showWikiEdit = true
            } label: {
              Label("编辑 Wiki", systemImage: "pencil")
            }
            Divider()
          }
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
          ToolbarCircle {
            Image(systemName: "ellipsis")
          }
        }
      }
    }
    .sheet(isPresented: $showIndexPicker) {
      IndexPickerSheet(
        category: .episode,
        itemId: episodeId,
        itemTitle: "章节详情"
      )
    }
    .sheet(isPresented: $showWikiEdit) {
      EpisodeWikiEditSheet(episodeId: episodeId) {
        Task {
          await loadCached()
        }
      }
    }
  }
}
