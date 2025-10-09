// ref: https://github.com/bangumi/server-private/blob/master/lib/notify.ts

import Foundation
import SwiftUI

struct NoticeRowView: View {
  @Binding var notice: NoticeDTO

  var statusColor: Color {
    notice.unread ? .accent : .secondary.opacity(0.2)
  }

  var body: some View {
    HStack(alignment: .top) {
      ImageView(img: notice.sender.avatar?.large)
        .imageStyle(width: 40, height: 40)
        .imageType(.avatar)
        .imageLink(notice.sender.link)
      HStack(alignment: .top) {
        Rectangle()
          .frame(width: 4)
          .foregroundStyle(statusColor)
        VStack(alignment: .leading) {
          HStack {
            Text(notice.sender.nickname.withLink(notice.sender.link))
            Spacer()
            Text(notice.createdAt.datetimeDisplay)
              .font(.footnote)
              .foregroundStyle(.secondary)
              .lineLimit(1)
          }
          Text(notice.desc)
        }
      }
    }.animation(.default, value: notice)
    Divider()
  }
}
