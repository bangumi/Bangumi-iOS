import BBCode
import SwiftUI

struct EpisodeCommentItemView: View {
  let comment: EpisodeCommentDTO

  var body: some View {
    VStack(alignment: .leading) {
      HStack(alignment: .top) {
        ImageView(img: comment.user.avatar?.large)
          .imageStyle(width: 40, height: 40)
          .imageType(.avatar)
          .imageLink(comment.user.link)
        VStack(alignment: .leading) {
          Text(comment.user.header)
          Text(comment.createdAt.datetimeDisplay)
            .font(.caption)
            .foregroundStyle(.secondary)
          BBCodeView(comment.content)
          ForEach(comment.replies) { reply in
            VStack(alignment: .leading) {
              Divider()
              HStack(alignment: .top) {
                ImageView(img: reply.user.avatar?.large)
                  .imageStyle(width: 40, height: 40)
                  .imageType(.avatar)
                  .imageLink(reply.user.link)
                VStack(alignment: .leading) {
                  Text(reply.user.header)
                  Text(reply.createdAt.datetimeDisplay)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                  BBCodeView(reply.content)
                }
              }
            }
          }
        }
      }
      Divider()
    }
  }
}
