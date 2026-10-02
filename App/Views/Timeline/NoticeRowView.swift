// ref: https://github.com/bangumi/server-private/blob/master/lib/notify.ts

import SwiftUI

struct NoticeRowView: View {
  let notice: NoticeDTO
  let onOpen: () -> Void

  @Environment(\.openURL) private var openURL

  var body: some View {
    row
      .listRowBackground(
        notice.unread
          ? Color.accent.opacity(0.05)
          : Color.clear
      )
  }

  @ViewBuilder
  private var row: some View {
    if let url = notice.targetURL {
      Button {
        onOpen()
        openURL(url)
      } label: {
        rowContent(linksSender: false)
          .contentShape(Rectangle())
      }
      .buttonStyle(.plain)
    } else {
      rowContent(linksSender: true)
    }
  }

  private func rowContent(linksSender: Bool) -> some View {
    HStack(alignment: .top, spacing: 12) {
      senderAvatar(linksSender: linksSender)

      VStack(alignment: .leading, spacing: 6) {
        HStack(alignment: .center, spacing: 8) {
          senderName(linksSender: linksSender)

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

        Text(notice.message)
          .font(.body)
          .foregroundColor(notice.unread ? .primary : .secondary)
          .lineLimit(3)
          .fixedSize(horizontal: false, vertical: true)
      }
    }
  }

  @ViewBuilder
  private func senderAvatar(linksSender: Bool) -> some View {
    let avatar = ImageView(img: notice.sender.avatar?.large)
      .imageStyle(width: 48, height: 48)
      .imageType(.avatar)
      .overlay(
        RoundedRectangle(cornerRadius: 24)
          .stroke(notice.unread ? Color.accent.opacity(0.3) : Color.clear, lineWidth: 2)
      )
    if linksSender, let url = senderURL {
      Button {
        onOpen()
        openURL(url)
      } label: {
        avatar
      }
      .buttonStyle(.plain)
    } else {
      avatar
    }
  }

  @ViewBuilder
  private func senderName(linksSender: Bool) -> some View {
    let name = Text(notice.sender.nickname)
      .font(.subheadline)
      .fontWeight(notice.unread ? .semibold : .regular)
      .lineLimit(1)
    if linksSender, let url = senderURL {
      Button {
        onOpen()
        openURL(url)
      } label: {
        name
          .contentShape(Rectangle())
      }
      .buttonStyle(.plain)
    } else {
      name
    }
  }

  private var senderURL: URL? {
    notice.sender.username.isEmpty ? nil : URL(string: notice.sender.link)
  }
}
