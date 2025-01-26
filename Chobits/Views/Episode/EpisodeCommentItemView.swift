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
          HStack {
            Text(comment.user.header).lineLimit(1)
            Spacer()
            Text(comment.createdAt.datetimeDisplay)
              .lineLimit(1)
              .font(.caption)
              .foregroundStyle(.secondary)
          }
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
                  HStack {
                    Text(reply.user.nickname.withLink(reply.user.link))
                      .lineLimit(1)
                    Spacer()
                    Text(reply.createdAt.datetimeDisplay)
                      .lineLimit(1)
                      .font(.caption)
                      .foregroundStyle(.secondary)
                  }
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
