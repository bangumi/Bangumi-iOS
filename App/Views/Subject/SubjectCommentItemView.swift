import SwiftUI

struct SubjectCommentItemView: View {
  let subjectType: SubjectType
  let comment: SubjectCommentDTO

  @State private var reactions: [ReactionDTO]

  init(subjectType: SubjectType, comment: SubjectCommentDTO) {
    self.subjectType = subjectType
    self.comment = comment
    self._reactions = State(initialValue: comment.reactions ?? [])
  }

  var body: some View {
    CardView {
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
            HStack(spacing: 2) {
              Text("\(comment.type.description(subjectType))")
              Text("@")
              Text(comment.updatedAt.relativeDisplay).monospacedDigit().lineLimit(1)
            }
            .font(.caption)
            .foregroundStyle(.secondary)
            Spacer()
            ReactionButton(type: .subjectCollect(comment.id), reactions: $reactions)
              .font(.footnote)
              .foregroundStyle(.secondary)
          }
          Text(comment.comment)
            .font(.footnote)
            .textSelection(.enabled)
          if !reactions.isEmpty {
            ReactionsView(type: .subjectCollect(comment.id), reactions: $reactions)
          }
        }
        Spacer()
      }
    }
    .blocklistFilter(comment.user.id, placeholder: false)
  }
}
