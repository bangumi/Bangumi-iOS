import OSLog
import SwiftData
import SwiftUI

struct SubjectReviewListView: View {
  let subjectId: Int

  @AppStorage("hideBlocklist") var hideBlocklist: Bool = false
  @AppStorage("blocklist") var blocklist: [Int] = []

  @State private var reloader = false

  func load(limit: Int, offset: Int) async -> PagedDTO<SubjectReviewDTO>? {
    do {
      let resp = try await Chii.shared.getSubjectReviews(subjectId, limit: limit, offset: offset)
      return resp
    } catch {
      Notifier.shared.alert(error: error)
    }
    return nil
  }

  var body: some View {
    ScrollView {
      PageView<SubjectReviewDTO, _>(reloader: reloader, nextPageFunc: load) { review in
        if !hideBlocklist || !blocklist.contains(review.user.id) {
          SubjectReviewItemView(item: review)
        }
      }.padding(.horizontal, 8)
    }
    .buttonStyle(.navigation)
    .navigationTitle("评论")
    .navigationBarTitleDisplayMode(.inline)
  }
}

#Preview {
  let container = mockContainer()
  let subject = Subject.previewAnime
  container.mainContext.insert(subject)

  return ScrollView {
    LazyVStack(alignment: .leading) {
      SubjectReviewListView(subjectId: subject.subjectId)
    }.padding()
  }.modelContainer(container)
}
