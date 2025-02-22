import SwiftUI

struct RakuenSubjectTopicView: View {
  let mode: SubjectTopicFilterMode

  @State private var reloader = false

  private func load(limit: Int, offset: Int) async -> PagedDTO<SubjectTopicDTO>? {
    do {
      switch mode {
      case .trending:
        let resp = try await Chii.shared.getTrendingSubjectTopics(limit: limit, offset: offset)
        return resp
      case .latest:
        let resp = try await Chii.shared.getRecentSubjectTopics(limit: limit, offset: offset)
        return resp
      }
    } catch {
      Notifier.shared.alert(error: error)
      return nil
    }
  }

  var body: some View {
    ScrollView {
      PageView<SubjectTopicDTO, _>(reloader: reloader, nextPageFunc: load) { topic in
        CardView {
          SubjectTopicItemView(topic: topic)
        }
      }.padding(.horizontal, 8)
    }
    .navigationTitle(mode.description)
    .navigationBarTitleDisplayMode(.inline)
    .refreshable {
      reloader.toggle()
    }
  }
}
