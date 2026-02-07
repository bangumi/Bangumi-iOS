import OSLog
import SwiftData
import SwiftUI

struct SubjectCommentListView: View {
  let subjectId: Int

  @AppStorage("hideBlocklist") var hideBlocklist: Bool = false
  @AppStorage("profile") var profile: Profile = Profile()

  @State private var reloader = false

  @Query private var subjects: [Subject]
  private var subject: Subject? { subjects.first }

  init(subjectId: Int) {
    self.subjectId = subjectId
    _subjects = Query(
      filter: #Predicate<Subject> {
        $0.subjectId == subjectId
      })
  }

  func load(limit: Int, offset: Int) async -> PagedDTO<SubjectCommentDTO>? {
    do {
      let resp = try await Chii.shared.getSubjectComments(subjectId, limit: limit, offset: offset)
      return resp
    } catch {
      Notifier.shared.alert(error: error)
    }
    return nil
  }

  var body: some View {
    ScrollView {
      PageView<SubjectCommentDTO, _>(reloader: reloader, nextPageFunc: load) { comment in
        SubjectCommentItemView(subjectType: subject?.typeEnum ?? .none, comment: comment)
      }.padding(.horizontal, 8)
    }
    .buttonStyle(.navigation)
    .navigationTitle("吐槽")
    .navigationBarTitleDisplayMode(.inline)
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
