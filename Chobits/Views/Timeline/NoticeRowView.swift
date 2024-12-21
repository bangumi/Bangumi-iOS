// ref: https://github.com/bangumi/server-private/blob/master/lib/notify.ts

import Foundation
import SwiftUI

struct NoticeRowView: View {
  @Binding var notice: NoticeDTO

  var body: some View {
    HStack {
      if notice.unread {
        Circle()
          .frame(width: 10, height: 10)
          .foregroundStyle(.accent)
      }
      NavigationLink(value: NavDestination.user(notice.sender.uid)) {
        ImageView(img: notice.sender.avatar?.large)
          .imageStyle(width: 40, height: 40)
          .imageType(.avatar)
      }
      VStack(alignment: .leading) {
        HStack {
          NavigationLink(value: NavDestination.user(notice.sender.uid)) {
            Text(notice.sender.nickname)
              .lineLimit(1)
          }.buttonStyle(.navLink)
          Spacer()
          Text(notice.createdAt.datetimeDisplay)
            .font(.footnote)
            .foregroundStyle(.secondary)
            .lineLimit(1)
        }
        HStack {
          switch notice.type {
          case 1:
            Text("在你的小组话题")
            Text(notice.title)
            Text("中发表了新回复")
          case 2:
            Text("在小组话题")
            Text(notice.title)
            Text("中回复了你")
          case 3:
            Text("在你的条目讨论")
            Text(notice.title)
            Text("中发表了新回复")
          case 4:
            Text("在条目讨论")
            Text(notice.title)
            Text("中回复了你")
          case 5:
            Text("在角色讨论")
            Text(notice.title)
            Text("中发表了新回复")
          case 6:
            Text("在角色")
            Text(notice.title)
            Text("中回复了你")
          case 7:
            Text("在你的日志")
            Text(notice.title)
            Text("中发表了新回复")
          case 8:
            Text("在日志")
            Text(notice.title)
            Text("中回复了你")
          case 9:
            Text("在章节讨论")
            Text(notice.title)
            Text("中发表了新回复")
          case 10:
            Text("在章节讨论")
            Text(notice.title)
            Text("中回复了你")
          case 11:
            Text("在目录")
            Text(notice.title)
            Text("中给你留言了")
          case 12:
            Text("在目录")
            Text(notice.title)
            Text("中回复了你")
          case 13:
            Text("在人物")
            Text(notice.title)
            Text("中回复了你")
          case 14:
            Text("请求与你成为好友")
          case 15:
            Text("通过了你的好友请求")
          case 17:
            Text("在你的社团讨论")
            Text(notice.title)
            Text("中发表了新回复")
          case 18:
            Text("在社团讨论")
            Text(notice.title)
            Text("中回复了你")
          case 19:
            Text("在同人作品")
            Text(notice.title)
            Text("中回复了你")
          case 20:
            Text("在你的展会讨论")
            Text(notice.title)
            Text("中发表了新回复")
          case 21:
            Text("在展会讨论")
            Text(notice.title)
            Text("中回复了你")
          case 22:
            Text("回复了你的 ")
            Text(notice.title)
            Text(" 吐槽")
          case 23:
            Text("在小组话题")
            Text(notice.title)
            Text("中提到了你")
          case 24:
            Text("在条目讨论")
            Text(notice.title)
            Text("中提到了你")
          case 25:
            Text("在角色")
            Text(notice.title)
            Text("中提到了你")
          case 26:
            Text("在人物讨论")
            Text(notice.title)
            Text("中提到了你")
          case 27:
            Text("在目录")
            Text(notice.title)
            Text("中提到了你")
          case 28:
            Text("在")
            Text(notice.title)
            Text("中提到了你")
          case 29:
            Text("在日志")
            Text(notice.title)
            Text("中提到了你")
          case 30:
            Text("在章节讨论")
            Text(notice.title)
            Text("中提到了你")
          case 31:
            Text("在社团")
            Text(notice.title)
            Text("的留言板中提到了你")
          case 32:
            Text("在社团讨论")
            Text(notice.title)
            Text("中提到了你")
          case 33:
            Text("在同人作品")
            Text(notice.title)
            Text("中提到了你")
          case 34:
            Text("在展会讨论")
            Text(notice.title)
            Text("中提到了你")
          default:
            Text("未知通知类型")
          }
        }
        .lineLimit(1)
        .font(.callout)
      }
      Spacer()
    }
    Divider()
  }
}

#Preview {
  let container = mockContainer()

  return ScrollView {
    LazyVStack(alignment: .leading) {
      NoticeRowView(notice: .constant(NoticeDTO()))
        .modelContainer(container)
    }
  }.padding()
}
