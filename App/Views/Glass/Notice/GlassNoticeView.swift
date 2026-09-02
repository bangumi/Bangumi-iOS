import SwiftUI

struct GlassNoticeView: View {
  let notices: [NoticeDTO]
  let fetched: Bool
  let markAsRead: (Int) -> Void

  @Environment(\.theme) private var theme

  var body: some View {
    List {
      if !fetched {
        HStack {
          Spacer()
          ProgressView()
          Spacer()
        }
        .listRowSeparator(.hidden)
        .listRowBackground(Color.clear)
      } else if notices.isEmpty {
        ThemedEmptyState(
          systemImage: "bell.slash", title: "暂无提醒",
          description: "新的电波提醒会出现在这里"
        )
        .listRowSeparator(.hidden)
        .listRowBackground(Color.clear)
      } else {
        ForEach(notices) { notice in
          GlassNoticeRow(notice: notice) {
            if notice.unread {
              markAsRead(notice.id)
            }
          }
          .listRowInsets(.init(top: 6, leading: 16, bottom: 6, trailing: 16))
          .listRowSeparator(.hidden)
          .listRowBackground(GlassNoticeRowBackground(unread: notice.unread))
          .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            if notice.unread {
              Button {
                markAsRead(notice.id)
              } label: {
                Label("已读", systemImage: "checkmark")
              }
              .tint(theme.accent)
            }
          }
        }
      }
    }
    .listStyle(.plain)
  }
}

private struct GlassNoticeRowBackground: View {
  let unread: Bool

  @Environment(\.theme) private var theme

  var body: some View {
    RoundedRectangle(cornerRadius: theme.metrics.embedRadius, style: .continuous)
      .fill(unread ? theme.cardFillStrong : theme.cardFill)
      .overlay {
        RoundedRectangle(cornerRadius: theme.metrics.embedRadius, style: .continuous)
          .fill(unread ? theme.tint : Color.clear)
      }
      .overlay {
        RoundedRectangle(cornerRadius: theme.metrics.embedRadius, style: .continuous)
          .strokeBorder(unread ? theme.accent.opacity(0.35) : theme.cardBorder, lineWidth: 1)
      }
      .padding(.vertical, 2)
  }
}

struct GlassNoticeRow: View {
  let notice: NoticeDTO
  let onOpen: () -> Void

  @Environment(\.theme) private var theme

  @ViewBuilder
  var body: some View {
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

  private func rowContent(linksSender: Bool) -> some View {
    HStack(alignment: .top, spacing: 11) {
      senderAvatar(linksSender: linksSender)

      VStack(alignment: .leading, spacing: 6) {
        HStack(alignment: .center, spacing: 8) {
          senderName(linksSender: linksSender)

          Spacer(minLength: 4)

          if notice.unread {
            Circle()
              .fill(theme.accent)
              .frame(width: 6, height: 6)
          }

          GlassMonoCaption(text: notice.createdAt.datetimeDisplay)
        }

        Text(notice.message)
          .font(.subheadline)
          .foregroundStyle(notice.unread ? theme.body : theme.secondaryText)
          .tint(theme.link)
          .lineLimit(3)
          .fixedSize(horizontal: false, vertical: true)
      }
    }
    .padding(.vertical, 9)
    .padding(.horizontal, 4)
  }

  @ViewBuilder
  private func senderAvatar(linksSender: Bool) -> some View {
    let avatar = ImageView(img: notice.sender.avatar?.large)
      .imageStyle(width: 38, height: 38)
      .imageType(.avatar)
      .glassAvatarRing(lineWidth: notice.unread ? 2 : 0)
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
      .font(.subheadline.weight(notice.unread ? .bold : .semibold))
      .foregroundStyle(linksSender ? theme.link : theme.cardTitle)
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
