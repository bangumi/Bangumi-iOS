import SwiftUI

struct UserHomeView: View {
  let user: UserDTO

  func ctypes(_ stype: SubjectType) -> [CollectionType: Int] {
    var result: [CollectionType: Int] = [:]
    for ct in CollectionType.allTypes() {
      guard let count = user.stats.subject.stats[stype]?[ct] else { continue }
      if count > 0 {
        result[ct] = count
      }
    }
    return result
  }

  var body: some View {
    VStack {
      ForEach(user.homepage.left, id: \.self) { section in
        VStack {
          switch section {
          case .none:
            EmptyView()

          case .anime:
            UserSubjectCollectionView(user: user, stype: .anime, ctypes: ctypes(.anime))

          case .blog:
            if user.stats.blog > 0 {
              UserBlogsView(user: user)
            }

          case .book:
            UserSubjectCollectionView(user: user, stype: .book, ctypes: ctypes(.book))

          case .friend:
            if user.stats.friend > 0 {
              UserFriendsView(user: user)
            }

          case .game:
            UserSubjectCollectionView(user: user, stype: .game, ctypes: ctypes(.game))

          case .group:
            if user.stats.group > 0 {
              UserGroupsView(user: user)
            }

          case .index:
            if user.stats.index.create > 0 {
              UserIndexesView(user: user)
            }

          case .mono:
            if user.stats.mono.character > 0 {
              UserCharacterCollectionView(user: user)
            }
            if user.stats.mono.person > 0 {
              UserPersonCollectionView(user: user)
            }

          case .music:
            UserSubjectCollectionView(user: user, stype: .music, ctypes: ctypes(.music))

          case .real:
            UserSubjectCollectionView(user: user, stype: .real, ctypes: ctypes(.real))
          }
        }
      }
    }
  }
}
