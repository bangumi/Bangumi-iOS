import OSLog
import SwiftUI

struct SubjectTopicListView: View {
  let subjectId: Int

  @AppStorage("hideBlocklist") var hideBlocklist: Bool = false
  @AppStorage("blocklist") var blocklist: [Int] = []

  @State private var reloader = false

  func load(limit: Int, offset: Int) async -> PagedDTO<TopicDTO>? {
    do {
      let resp = try await SubjectService.getSubjectTopics(subjectId, limit: limit, offset: offset)
      return resp
    } catch {
      Notifier.shared.alert(error: error)
    }
    return nil
  }

  var body: some View {
    ScrollView {
      OffsetPagedView<TopicDTO, _>(reloader: reloader, nextPageFunc: load) { topic in
        if !hideBlocklist || !blocklist.contains(topic.creator?.id ?? 0) {
          SubjectTopicItemView(topic: topic)
        }
      }.padding(.horizontal, 8)
    }
    .buttonStyle(.navigation)
    .navigationTitle("讨论版")
    .navigationBarTitleDisplayMode(.inline)
  }
}
