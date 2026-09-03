import SwiftUI

struct GlassUserNotFound: View {
  let username: String

  @Environment(\.dismiss) private var dismiss
  @Environment(\.theme) private var theme

  init(username: String) {
    self.username = username
  }

  var body: some View {
    VStack(spacing: 14) {
      Image("404")
        .resizable()
        .scaledToFit()
        .frame(width: 120, height: 120)
        .opacity(0.8)
      Text("没有找到这个用户")
        .font(.headline.weight(.heavy))
        .foregroundStyle(theme.sectionHeader)
      Text("@\(username) 可能已注销，或用户名拼写有误")
        .font(.footnote)
        .foregroundStyle(theme.tertiaryText)
        .multilineTextAlignment(.center)
      Button {
        dismiss()
      } label: {
        Text("返回")
          .font(.subheadline.weight(.bold))
          .foregroundStyle(theme.secondaryText)
          .padding(.horizontal, 22)
          .padding(.vertical, 9)
          .background(
            theme.controlFill,
            in: RoundedRectangle(cornerRadius: theme.metrics.controlRadius, style: .continuous)
          )
          .overlay {
            RoundedRectangle(cornerRadius: theme.metrics.controlRadius, style: .continuous)
              .strokeBorder(theme.controlBorder, lineWidth: 1)
          }
      }
      .buttonStyle(.plain)
      .padding(.top, 6)
    }
    .padding(.horizontal, 40)
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
  }
}

struct GlassUserDetailView: View {
  let user: UserDTO

  @Environment(\.theme) private var theme

  init(user: UserDTO) {
    self.user = user
  }

  var body: some View {
    ScrollView(showsIndicators: false) {
      VStack(alignment: .leading, spacing: theme.metrics.listSpacing) {
        GlassUserHeader(user: user)
        GlassUserSections(user: user)
        footer
      }
      .padding(.horizontal, theme.metrics.screenPadding)
      .padding(.top, 8)
      .padding(.bottom, 26)
    }
  }

  private var footer: some View {
    HStack(spacing: 12) {
      ThemedDivider()
      Text("没有更多了")
        .font(.caption)
        .foregroundStyle(theme.placeholder)
        .fixedSize()
      ThemedDivider()
    }
    .padding(.horizontal, 8)
    .padding(.top, 12)
  }
}

struct GlassUserView: View {
  let username: String
  let user: UserDTO?
  let notFound: Bool
  let shareLink: URL
  let onAddFriend: () -> Void
  let onRemoveFriend: () -> Void
  let onBlock: () -> Void
  let onUnblock: () -> Void

  @State private var showMore = false
  @State private var showReport = false
  @State private var destination: NavDestination?
  @State private var pendingDestination: NavDestination?
  @State private var pendingReport = false

  private func applyPendingAction() {
    if let pendingDestination {
      self.pendingDestination = nil
      destination = pendingDestination
      return
    }
    if pendingReport {
      pendingReport = false
      showReport = true
    }
  }

  var body: some View {
    content
      .toolbar {
        ToolbarItem(placement: .topBarTrailing) {
          Button {
            showMore = true
          } label: {
            ToolbarCircle {
              Image(systemName: "ellipsis")
            }
          }
          .buttonStyle(.plain)
          .disabled(user == nil)
        }
      }
      .sheet(isPresented: $showMore, onDismiss: applyPendingAction) {
        if let user {
          GlassUserMoreSheet(
            user: user,
            shareLink: shareLink,
            onNavigate: { pendingDestination = $0 },
            onAddFriend: onAddFriend,
            onRemoveFriend: onRemoveFriend,
            onBlock: onBlock,
            onUnblock: onUnblock,
            onReport: { pendingReport = true }
          )
        }
      }
      .sheet(isPresented: $showReport) {
        if let user {
          ReportSheet(
            reportType: .user, itemId: user.id, itemTitle: user.nickname, user: user.slim
          )
        }
      }
      .navigationDestination(item: $destination) { destination in
        destination
      }
  }

  @ViewBuilder
  private var content: some View {
    if let user {
      UserDetailView(user: user)
    } else if notFound {
      GlassUserNotFound(username: username)
    } else {
      ProgressView()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
  }
}
