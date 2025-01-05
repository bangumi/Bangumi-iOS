import SwiftUI

struct UserHomeView: View {
  @Environment(User.self) var user

  @State private var width: CGFloat = 0

  var body: some View {
    VStack {
      ForEach(user.homepage.left, id: \.self) { section in
        VStack {
          switch section {
          case .none:
            EmptyView()

          case .anime:
            UserSubjectCollectionView(.anime, width)

          case .blog:
            UserBlogsView()

          case .book:
            UserSubjectCollectionView(.book, width)

          case .friend:
            UserFriendsView(width)

          case .game:
            UserSubjectCollectionView(.game, width)

          case .group:
            UserGroupsView(width)

          case .index:
            UserIndexesView()

          case .mono:
            UserCharacterCollectionView(width)
            UserPersonCollectionView(width)

          case .music:
            UserSubjectCollectionView(.music, width)

          case .real:
            UserSubjectCollectionView(.real, width)
          }
        }
      }
    }.onGeometryChange(for: CGSize.self) { proxy in
      proxy.size
    } action: { newSize in
      if self.width != newSize.width {
        self.width = newSize.width
      }
    }
  }
}
