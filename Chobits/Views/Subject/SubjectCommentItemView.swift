import SwiftUI

struct SubjectCommentItemView: View {
  let subjectType: SubjectType
  let comment: SubjectCommentDTO

  @State private var reactions: [ReactionDTO]

  @AppStorage("hideBlocklist") var hideBlocklist: Bool = false
  @AppStorage("profile") var profile: Profile = Profile()

  init(subjectType: SubjectType, comment: SubjectCommentDTO) {
    self.subjectType = subjectType
    self.comment = comment
    if let reactions = comment.reactions {
      self._reactions = State(initialValue: reactions)
    } else {
      self._reactions = State(initialValue: [])
    }
  }

  var body: some View {
    if !hideBlocklist || !profile.blocklist.contains(comment.user.id) {
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
              comment.header(subjectType)
                .lineLimit(1)
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
    }
  }
}
