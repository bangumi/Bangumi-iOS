import BBCode
import SwiftUI

struct ReplyItemNormalView: View {
  let reply: ReplyDTO

  var body: some View {
    VStack(alignment: .leading) {
      HStack(alignment: .top) {
        if let creator = reply.creator {
          ImageView(img: creator.avatar?.large)
            .imageStyle(width: 40, height: 40)
            .imageType(.avatar)
            .imageLink(creator.link)
        } else {
          Rectangle().fill(.clear).frame(width: 40, height: 40)
        }
        VStack(alignment: .leading) {
          HStack {
            if let creator = reply.creator {
              Text(creator.header).lineLimit(1)
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
          ForEach(reply.replies) { subreply in
            VStack(alignment: .leading) {
              Divider()
              HStack(alignment: .top) {
                if let user = subreply.creator {
                  ImageView(img: user.avatar?.large)
                    .imageStyle(width: 40, height: 40)
                    .imageType(.avatar)
                    .imageLink(user.link)
                } else {
                  Rectangle().fill(.clear).frame(width: 40, height: 40)
                }
                VStack(alignment: .leading) {
                  HStack {
                    if let user = subreply.creator {
                      Text(user.nickname.withLink(user.link))
                        .lineLimit(1)
                    } else {
                      Text("用户 \(subreply.creatorID)")
                        .lineLimit(1)
                    }
                    Spacer()
                    Text(subreply.createdAt.datetimeDisplay)
                      .lineLimit(1)
                      .font(.caption)
                      .foregroundStyle(.secondary)
                  }
                  BBCodeView(subreply.content)
                    .textSelection(.enabled)
                }
              }
            }
          }
        }
      }
    }
  }
}

struct ReplyItemView: View {
  let reply: ReplyDTO

  var body: some View {
    switch reply.state {
    case .userDelete:
      HStack {
        if let creator = reply.creator {
          Text(creator.header).lineLimit(1)
        } else {
          Text("用户 \(reply.creatorID)")
            .lineLimit(1)
        }
        Text("删除了回复")
          .font(.footnote)
          .foregroundStyle(.secondary)
        Spacer()
        Text(reply.createdAt.datetimeDisplay)
          .lineLimit(1)
          .font(.caption)
          .foregroundStyle(.secondary)
      }
    default:
      ReplyItemNormalView(reply: reply)
    }
  }
}
