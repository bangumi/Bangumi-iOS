import SwiftUI

struct GlassUserRow: View {
  let user: SlimUserDTO
  var detail: String? = nil
  var note: String? = nil

  @Environment(\.theme) private var theme

  var body: some View {
    CardView(padding: 12) {
      HStack(alignment: .top, spacing: 12) {
        ImageView(img: user.avatar?.large)
          .imageStyle(
            width: 54, height: 54, cornerRadius: theme.metrics.embedRadius,
            alignment: .center
          )
          .imageType(.avatar)
          .imageLink(user.link)
        VStack(alignment: .leading, spacing: 3) {
          Text(user.nickname.withLink(user.link, linkColor: theme.cardTitle))
            .font(.subheadline.weight(.bold))
            .lineLimit(1)
          Text("@\(user.username)")
            .font(.caption.weight(.semibold).monospaced())
            .foregroundStyle(theme.tertiaryText)
            .lineLimit(1)
          if let detail {
            Text(detail)
              .font(.caption)
              .foregroundStyle(theme.placeholder)
              .lineLimit(1)
          }
          if let note, !note.isEmpty {
            Text(note)
              .font(.caption)
              .foregroundStyle(theme.secondaryText)
              .lineLimit(2)
          }
        }
        Spacer(minLength: 0)
      }
    }
  }
}

struct GlassFriendsView: View {
  @State private var reloader = false
  @State private var type: FriendType = .friends

  @Environment(\.theme) private var theme

  func load(limit: Int, offset: Int) async -> PagedDTO<FriendDTO>? {
    do {
      let resp = try await {
        switch type {
        case .friends:
          return try await FriendService.getFriends(limit: limit, offset: offset)
        case .followers:
          return try await FriendService.getFollowers(limit: limit, offset: offset)
        }
      }()
      return resp
    } catch {
      Notifier.shared.alert(error: error)
    }
    return nil
  }

  var body: some View {
    VStack(spacing: 0) {
      GlassSegmented(selection: $type, items: [.friends, .followers]) { item in
        Text(item.title)
      }
      .padding(.horizontal, theme.metrics.screenPadding)
      .padding(.vertical, 6)
      .onChange(of: type) { _, _ in
        withAnimation(.default) {
          reloader.toggle()
        }
      }
      ScrollView(showsIndicators: false) {
        OffsetPagedView<FriendDTO, _>(reloader: reloader, nextPageFunc: load) { item in
          GlassUserRow(
            user: item.user,
            detail: item.createdAt.datetimeDisplay,
            note: item.description
          )
        }
        .padding(.horizontal, theme.metrics.screenPadding)
        .padding(.bottom, 26)
      }
    }
    .navigationTitle(type.title)
    .navigationBarTitleDisplayMode(.inline)
  }
}
