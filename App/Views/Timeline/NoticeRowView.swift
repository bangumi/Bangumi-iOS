// ref: https://github.com/bangumi/server-private/blob/master/lib/notify.ts

import SwiftUI

struct NoticeRowView: View {
  let notice: NoticeDTO
  let onOpen: () -> Void

  @Environment(\.theme) private var theme

  var body: some View {
    ZStack {
      switch notice.target {
      case .app(let destination):
        NavigationLink(value: destination) {
          rowContent(linksSender: false)
        }
        .buttonStyle(.plain)
        .simultaneousGesture(openGesture)
      case .external(let url):
        Link(destination: url) {
          rowContent(linksSender: false)
        }
        .buttonStyle(.plain)
        .simultaneousGesture(openGesture)
      case nil:
        rowContent(linksSender: true)
      }
    }
    .listRowBackground(
      notice.unread
        ? theme.accent.opacity(0.05)
        : Color.clear
    )
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
                .fill(theme.accent)
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
          .foregroundColor(notice.unread ? theme.body : theme.secondaryText)
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
          .stroke(notice.unread ? theme.accent.opacity(0.3) : Color.clear, lineWidth: 2)
      )
    if linksSender && !notice.sender.username.isEmpty {
      NavigationLink(value: NavDestination.user(notice.sender.username)) {
        avatar
      }
      .buttonStyle(.plain)
      .simultaneousGesture(openGesture)
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
    if linksSender && !notice.sender.username.isEmpty {
      NavigationLink(value: NavDestination.user(notice.sender.username)) {
        name
      }
      .buttonStyle(.plain)
      .simultaneousGesture(openGesture)
    } else {
      name
    }
  }

  private var openGesture: some Gesture {
    TapGesture().onEnded {
      onOpen()
    }
  }
}
