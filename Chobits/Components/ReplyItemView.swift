import BBCode
import SwiftUI

struct ReplyItemNormalView: View {
  let idx: Int
  let reply: ReplyDTO
  let author: SlimUserDTO

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
              if creator.id == author.id {
                BorderView {
                  Text("楼主")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }
              }
              Text(creator.header).lineLimit(1)
            } else {
              Text("用户 \(reply.creatorID)")
                .lineLimit(1)
            }
            Spacer()
            Text("#\(idx+1) - \(reply.createdAt.datetimeDisplay)")
              .lineLimit(1)
              .font(.caption)
              .foregroundStyle(.secondary)
          }
          BBCodeView(reply.content).textSelection(.enabled)
          ForEach(Array(zip(reply.replies.indices, reply.replies)), id: \.1) { subidx, subreply in
            VStack(alignment: .leading) {
              Divider()
              switch subreply.state {
              case .userDelete:
                ReplyUserDeleteView(idx: subidx, reply: subreply, author: author)
              default:
                ReplyBaseNormalView(idx: idx, subidx: subidx, subreply: subreply, author: author)
              }
            }
          }
        }
      }
    }
  }
}

struct ReplyUserDeleteView: View {
  let idx: Int
  let reply: ReplyBaseDTO
  let author: SlimUserDTO

  var body: some View {
    HStack {
      if let creator = reply.creator {
        if creator.id == author.id {
          BorderView {
            Text("楼主")
              .font(.caption)
              .foregroundStyle(.secondary)
          }
        }
        Text(creator.nickname.withLink(creator.link)).lineLimit(1)
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
  }
}

struct ReplyItemView: View {
  let idx: Int
  let reply: ReplyDTO
  let author: SlimUserDTO

  var body: some View {
    switch reply.state {
    case .userDelete:
      ReplyUserDeleteView(idx: idx, reply: reply.base, author: author)
    default:
      ReplyItemNormalView(idx: idx, reply: reply, author: author)
    }
  }
}

struct ReplyBaseNormalView: View {
  let idx: Int
  let subidx: Int
  let subreply: ReplyBaseDTO
  let author: SlimUserDTO

  var body: some View {
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
            if user.id == author.id {
              BorderView {
                Text("楼主")
                  .font(.caption)
                  .foregroundStyle(.secondary)
              }
            }
            Text(user.nickname.withLink(user.link))
              .lineLimit(1)
          } else {
            Text("用户 \(subreply.creatorID)")
              .lineLimit(1)
          }
          Spacer()
          Text("#\(idx + 1)-\(subidx + 1) - \(subreply.createdAt.datetimeDisplay)")
            .lineLimit(1)
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        BBCodeView(subreply.content).textSelection(.enabled)
      }
    }
  }
}
