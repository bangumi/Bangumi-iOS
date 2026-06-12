import OSLog
import SwiftUI

struct SubjectCommentListView: View {
  let subjectId: Int

  @AppStorage("hideBlocklist") var hideBlocklist: Bool = false
  @AppStorage("profile") var profile: Profile = Profile()

  @State private var reloader = false
  @State private var subjectType: SubjectType = .none

  init(subjectId: Int) {
    self.subjectId = subjectId
  }

  func loadCachedSubjectType() async {
    guard let db = await AppContext.shared.databaseIfAvailable() else { return }
    subjectType = (try? await db.getSubjectDTO(subjectId)?.type) ?? .none
  }

  func load(limit: Int, offset: Int) async -> PagedDTO<SubjectCommentDTO>? {
    do {
      let resp = try await SubjectService.getSubjectComments(
        subjectId, limit: limit, offset: offset)
      return resp
    } catch {
      Notifier.shared.alert(error: error)
    }
    return nil
  }

  var body: some View {
    ScrollView {
      PageView<SubjectCommentDTO, _>(reloader: reloader, nextPageFunc: load) { comment in
        SubjectCommentItemView(subjectType: subjectType, comment: comment)
      }.padding(.horizontal, 8)
    }
    .buttonStyle(.navigation)
    .navigationTitle("吐槽")
    .navigationBarTitleDisplayMode(.inline)
    .task(id: subjectId) {
      await loadCachedSubjectType()
    }
  }
}

#Preview {
  let container = mockContainer()

  let subject = Subject.previewAnime
  container.mainContext.insert(subject)

  return ScrollView {
    LazyVStack(alignment: .leading) {
      SubjectCommentListView(subjectId: subject.subjectId)
    }.padding()
  }.modelContainer(container)
}
