// ref: https://github.com/bangumi/server-private/blob/master/lib/notify.ts

import Foundation
import SwiftUI

struct NoticeRowView: View {
  @Binding var notice: NoticeDTO

  var statusColor: Color {
    notice.unread ? .accent : .secondary.opacity(0.2)
  }

  var body: some View {
    HStack(alignment: .top, spacing: 12) {
      ImageView(img: notice.sender.avatar?.large)
        .imageStyle(width: 48, height: 48)
        .imageType(.avatar)
        .imageLink(notice.sender.link)
        .overlay(
          RoundedRectangle(cornerRadius: 24)
            .stroke(notice.unread ? Color.accent.opacity(0.3) : Color.clear, lineWidth: 2)
        )

      VStack(alignment: .leading, spacing: 6) {
        HStack(alignment: .center, spacing: 8) {
          Text(notice.sender.nickname.withLink(notice.sender.link))
            .font(.subheadline)
            .fontWeight(notice.unread ? .semibold : .regular)
            .lineLimit(1)

          Spacer(minLength: 4)

          HStack(spacing: 4) {
            if notice.unread {
              Circle()
                .fill(Color.accent)
                .frame(width: 6, height: 6)
            }

            Text(notice.createdAt.datetimeDisplay)
              .font(.caption)
              .foregroundStyle(.secondary)
              .lineLimit(1)
          }
        }

        Text(notice.desc)
          .font(.body)
          .foregroundColor(notice.unread ? .primary : .secondary)
          .lineLimit(3)
          .fixedSize(horizontal: false, vertical: true)
      }
    }
    .listRowBackground(
      notice.unread
        ? Color.accent.opacity(0.05)
        : Color.clear
    )
  }
}
