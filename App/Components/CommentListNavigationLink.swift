import SwiftUI

struct CommentListRoute: Hashable, Sendable {
  let parent: CommentParentType
  let initialPostID: Int?
  let timelineUsername: String?

  init(
    parent: CommentParentType,
    initialPostID: Int? = nil,
    timelineUsername: String? = nil
  ) {
    self.parent = parent
    self.initialPostID = initialPostID
    self.timelineUsername = timelineUsername
  }
}

struct CommentListNavigationLink: View {
  let route: CommentListRoute
  let title: LocalizedStringResource
  let count: Int?

  init(
    route: CommentListRoute,
    title: LocalizedStringResource = "吐槽箱",
    count: Int? = nil
  ) {
    self.route = route
    self.title = title
    self.count = count
  }

  var body: some View {
    NavigationLink(value: NavDestination.commentList(route)) {
      HStack(spacing: 10) {
        Image(systemName: "bubble.left.and.bubble.right")
          .font(.body)
          .foregroundStyle(Color.accentColor)
          .frame(width: 20)

        Text(title)
          .font(.subheadline.weight(.semibold))

        Spacer(minLength: 6)

        if let count {
          Text("\(count)")
            .font(.footnote)
            .foregroundStyle(.secondary)
            .monospacedDigit()
        }

        Image(systemName: "chevron.forward")
          .font(.footnote.weight(.semibold))
          .foregroundStyle(.tertiary)
      }
      .padding(.horizontal, 12)
      .padding(.vertical, 9)
      .contentShape(Rectangle())
      .background(
        Color(uiColor: .secondarySystemBackground),
        in: RoundedRectangle(cornerRadius: 10, style: .continuous)
      )
      .overlay {
        RoundedRectangle(cornerRadius: 10, style: .continuous)
          .stroke(Color(uiColor: .separator).opacity(0.22), lineWidth: 0.5)
      }
    }
    .buttonStyle(.plain)
  }
}
