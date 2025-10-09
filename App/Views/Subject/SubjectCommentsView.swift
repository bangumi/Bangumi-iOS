import SwiftUI

struct SubjectCommentsView: View {
  let subjectId: Int
  let subjectType: SubjectType
  let comments: [SubjectCommentDTO]

  @AppStorage("hideBlocklist") var hideBlocklist: Bool = false
  @AppStorage("profile") var profile: Profile = Profile()

  var body: some View {
    VStack(spacing: 2) {
      HStack(alignment: .bottom) {
        Text("吐槽箱")
          .foregroundStyle(comments.count > 0 ? .primary : .secondary)
          .font(.title3)
        Spacer()
        if comments.count > 0 {
          NavigationLink(value: NavDestination.subjectCommentList(subjectId)) {
            Text("更多吐槽 »").font(.caption)
          }.buttonStyle(.navigation)
        }
      }
      Divider()
    }.padding(.top, 5)
    if comments.count == 0 {
      HStack {
        Spacer()
        Text("暂无吐槽")
          .font(.caption)
          .foregroundStyle(.secondary)
        Spacer()
      }.padding(.bottom, 5)
    }
    VStack {
      ForEach(comments) { comment in
        SubjectCommentItemView(subjectType: subjectType, comment: comment)
      }
    }.animation(.default, value: comments)
  }
}

#Preview {
  NavigationStack {
    ScrollView {
      LazyVStack(alignment: .leading) {
        SubjectCommentsView(
          subjectId: Subject.previewAnime.subjectId,
          subjectType: Subject.previewAnime.typeEnum,
          comments: Subject.previewComments
        )
      }.padding()
    }
  }
}
