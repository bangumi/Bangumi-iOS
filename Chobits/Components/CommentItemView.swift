import BBCode
import SwiftUI

struct CommentItemView: View {
  let comment: CommentDTO

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
            .textSelection(.enabled)
          ForEach(comment.replies) { reply in
            VStack(alignment: .leading) {
              Divider()
              HStack(alignment: .top) {
                if let user = reply.user {
                  ImageView(img: user.avatar?.large)
                    .imageStyle(width: 40, height: 40)
                    .imageType(.avatar)
                    .imageLink(user.link)
                } else {
                  Rectangle().fill(.clear).frame(width: 40, height: 40)
                }
                VStack(alignment: .leading) {
                  HStack {
                    if let user = reply.user {
                      Text(user.nickname.withLink(user.link))
                        .lineLimit(1)
                    } else {
                      Text("用户 \(reply.creatorID)")
                        .lineLimit(1)
                    }
                    Spacer()
                    Text(reply.createdAt.datetimeDisplay)
                      .lineLimit(1)
                      .font(.caption)
                      .foregroundStyle(.secondary)
                  }
                  BBCodeView(reply.content)
                    .textSelection(.enabled)
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
