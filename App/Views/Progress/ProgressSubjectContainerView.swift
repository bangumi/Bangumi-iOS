import SwiftUI

struct ProgressSubjectContainerView<Content: View>: View {
  let subjectId: Int
  let reloadToken: Int
  let episodeWindowSize: Int
  let content: (ProgressSubjectDTO, @escaping () async -> Void) -> Content

  @State private var item: ProgressSubjectDTO?
  @State private var loaded = false

  init(
    subjectId: Int,
    reloadToken: Int = 0,
    episodeWindowSize: Int = 7,
    @ViewBuilder content: @escaping (ProgressSubjectDTO, @escaping () async -> Void) -> Content
  ) {
    self.subjectId = subjectId
    self.reloadToken = reloadToken
    self.episodeWindowSize = episodeWindowSize
    self.content = content
  }

  private func load() async {
    loaded = false
    do {
      let db = try await AppContext.shared.getDB()
      item = try await db.fetchProgressSubject(
        subjectId: subjectId,
        episodeWindowSize: episodeWindowSize
      )
    } catch {
      Notifier.shared.alert(error: error)
    }
    loaded = true
  }

  var body: some View {
    Group {
      if let item {
        content(item, load)
      } else if !loaded {
        ProgressView()
          .frame(maxWidth: .infinity)
          .padding()
      }
    }
    .task(id: "\(subjectId)-\(reloadToken)") {
      await load()
    }
  }
}
