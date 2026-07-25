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
      HStack(spacing: 4) {
        Image(systemName: "bubble.left.and.bubble.right")
          .accessibilityLabel(Text(title))

        if let count {
          Text("\(count)")
            .monospacedDigit()
        }
      }
      .font(.footnote)
      .lineLimit(1)
    }
    .buttonStyle(.navigation)
  }
}
