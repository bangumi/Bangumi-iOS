import SwiftUI

struct UserHomeView: View {
  @Environment(User.self) var user

  func ctypes(_ stype: SubjectType) -> [CollectionType: Int] {
    var result: [CollectionType: Int] = [:]
    for ct in CollectionType.allTypes() {
      guard let count = user.stats?.subject.stats[stype]?[ct] else { continue }
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
            UserSubjectCollectionView(.anime, ctypes(.anime))

          case .blog:
            if let count = user.stats?.blog, count > 0 {
              UserBlogsView()
            }

          case .book:
            UserSubjectCollectionView(.book, ctypes(.book))

          case .friend:
            if let count = user.stats?.friend, count > 0 {
              UserFriendsView()
            }

          case .game:
            UserSubjectCollectionView(.game, ctypes(.game))

          case .group:
            if let count = user.stats?.group, count > 0 {
              UserGroupsView()
            }

          case .index:
            if let count = user.stats?.index.create, count > 0 {
              UserIndexesView()
            }

          case .mono:
            if let count = user.stats?.mono.character, count > 0 {
              UserCharacterCollectionView()
            }
            if let count = user.stats?.mono.person, count > 0 {
              UserPersonCollectionView()
            }

          case .music:
            UserSubjectCollectionView(.music, ctypes(.music))

          case .real:
            UserSubjectCollectionView(.real, ctypes(.real))
          }
        }
      }
    }
  }
}
