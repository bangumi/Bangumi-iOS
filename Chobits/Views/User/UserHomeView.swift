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
    GeometryReader { geometry in
      VStack {
        ForEach(user.homepage.left, id: \.self) { section in
          VStack {
            switch section {
            case .none:
              EmptyView()

            case .anime:
              UserSubjectCollectionView(geometry.size.width, .anime, ctypes(.anime))

            case .blog:
              if let count = user.stats?.blog, count > 0 {
                UserBlogsView()
              }

            case .book:
              UserSubjectCollectionView(geometry.size.width, .book, ctypes(.book))

            case .friend:
              if let count = user.stats?.friend, count > 0 {
                UserFriendsView(geometry.size.width)
              }

            case .game:
              UserSubjectCollectionView(geometry.size.width, .game, ctypes(.game))

            case .group:
              if let count = user.stats?.group, count > 0 {
                UserGroupsView(geometry.size.width)
              }

            case .index:
              if let count = user.stats?.index.create, count > 0 {
                UserIndexesView()
              }

            case .mono:
              if let count = user.stats?.mono.character, count > 0 {
                UserCharacterCollectionView(geometry.size.width)
              }
              if let count = user.stats?.mono.person, count > 0 {
                UserPersonCollectionView(geometry.size.width)
              }

            case .music:
              UserSubjectCollectionView(geometry.size.width, .music, ctypes(.music))

            case .real:
              UserSubjectCollectionView(geometry.size.width, .real, ctypes(.real))
            }
          }
        }
      }
    }
  }
}
