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
        if !hideBlocklist || !profile.blocklist.contains(comment.user.id) {
          HStack(alignment: .top) {
            ImageView(img: comment.user.avatar?.large)
              .imageStyle(width: 32, height: 32)
              .imageType(.avatar)
              .imageLink(comment.user.link)
            VStack(alignment: .leading) {
              HStack {
                Text(comment.user.nickname.withLink(comment.user.link))
                  .font(.footnote)
                  .lineLimit(1)
                if comment.rate > 0 {
                  StarsView(score: Float(comment.rate), size: 10)
                }
                comment.header(subject?.typeEnum ?? .none)
                  .lineLimit(1)
                  .font(.caption)
                  .foregroundStyle(.secondary)
                Spacer()
              }
              Text(comment.comment).font(.footnote)
            }
            Spacer()
          }.padding(.top, 2)
        }
      }.padding(.horizontal, 8)
    }
    .buttonStyle(.navLink)
    .navigationTitle("吐槽")
    .navigationBarTitleDisplayMode(.inline)
    .toolbar {
      ToolbarItem(placement: .automatic) {
        Image(systemName: "list.bullet.circle").foregroundStyle(.secondary)
      }
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
