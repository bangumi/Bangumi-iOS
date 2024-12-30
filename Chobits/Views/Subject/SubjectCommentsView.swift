import SwiftUI

struct SubjectCommentsView: View {
  let subjectId: Int
  let subjectType: SubjectType
  let comments: [SubjectCommentDTO]

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
          }.buttonStyle(.navLink)
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
              Text(
                "\(comment.type.description(subjectType)) @ \(comment.updatedAt.relativeDateDisplay)"
              )
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
