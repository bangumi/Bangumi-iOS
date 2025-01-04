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
            Text("🚧 Blog")

          case .book:
            UserSubjectCollectionView(.book, width)

          case .friend:
            Text("🚧 Friend")

          case .game:
            UserSubjectCollectionView(.game, width)

          case .group:
            Text("🚧 Group")

          case .index:
            Text("🚧 Index")

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

struct UserSubjectCollectionView: View {
  let stype: SubjectType
  let width: CGFloat

  @Environment(User.self) var user

  @State private var ctype: CollectionType = .collect
  @State private var subjects: [SlimSubjectDTO] = []

  init(_ stype: SubjectType, _ width: CGFloat) {
    self.stype = stype
    self.width = width
  }

  var columnCount: Int {
    let columns = Int((width - 8) / 68)
    return columns > 0 ? columns : 1
  }

  var columns: [GridItem] {
    Array(repeating: .init(.flexible()), count: columnCount)
  }

  func refresh() async {
    do {
      let resp = try await Chii.shared.getUserSubjectCollections(
        username: user.username, type: ctype, subjectType: stype, limit: 12)
      subjects = resp.data.map { $0.subject.slim }
    } catch {
      Notifier.shared.alert(error: error)
    }
  }

  var body: some View {
    VStack {
      HStack {
        Text("\(user.nickname)的\(stype.description)").font(.title3)
        Spacer()
        NavigationLink(value: NavDestination.userCollection(user.slim)) {
          Text("更多 »")
            .font(.caption)
        }.buttonStyle(.navLink)
      }
      .padding(.top, 8)
      .task(refresh)

      Picker("Collection Type", selection: $ctype) {
        ForEach(CollectionType.allTypes()) { ct in
          Text(ct.description(stype)).tag(ct)
        }
      }
      .pickerStyle(.segmented)
      .onChange(of: ctype) { _, _ in
        Task {
          await refresh()
        }
      }

      LazyVGrid(columns: columns) {
        ForEach(subjects) { subject in
          ImageView(img: subject.images?.resize(.r200))
            .imageStyle(width: 60, height: 60)
            .imageType(.subject)
            .imageLink(subject.link)
        }
      }
    }.animation(.default, value: subjects)
  }
}

struct UserCharacterCollectionView: View {
  let width: CGFloat

  @Environment(User.self) var user

  @State private var characters: [SlimCharacterDTO] = []

  init(_ width: CGFloat) {
    self.width = width
  }

  var columnCount: Int {
    let columns = Int((width - 8) / 68)
    return columns > 0 ? columns : 1
  }

  var columns: [GridItem] {
    Array(repeating: .init(.flexible()), count: columnCount)
  }

  func refresh() async {
    do {
      let resp = try await Chii.shared.getUserCharacterCollections(
        username: user.username, limit: 12)
      characters = resp.data.map { $0.character.slim }
    } catch {
      Notifier.shared.alert(error: error)
    }
  }

  var body: some View {
    VStack(spacing: 2) {
      HStack(alignment: .bottom) {
        Text("\(user.nickname)收藏的角色").font(.title3)
        Spacer()
        NavigationLink(value: NavDestination.userMono(user.slim)) {
          Text("更多 »")
            .font(.caption)
        }.buttonStyle(.navLink)
      }
      .padding(.top, 8)
      .task(refresh)
      Divider()

      LazyVGrid(columns: columns) {
        ForEach(characters) { character in
          ImageView(img: character.images?.resize(.r200))
            .imageStyle(width: 60, height: 60)
            .imageType(.person)
            .imageLink(character.link)
        }
      }
    }.animation(.default, value: characters)
  }
}

struct UserPersonCollectionView: View {
  let width: CGFloat

  @Environment(User.self) var user

  @State private var persons: [SlimPersonDTO] = []

  init(_ width: CGFloat) {
    self.width = width
  }

  var columnCount: Int {
    let columns = Int((width - 8) / 68)
    return columns > 0 ? columns : 1
  }

  var columns: [GridItem] {
    Array(repeating: .init(.flexible()), count: columnCount)
  }

  func refresh() async {
    do {
      let resp = try await Chii.shared.getUserPersonCollections(
        username: user.username, limit: 12)
      persons = resp.data.map { $0.person.slim }
    } catch {
      Notifier.shared.alert(error: error)
    }
  }

  var body: some View {
    VStack(spacing: 2) {
      HStack(alignment: .bottom) {
        Text("\(user.nickname)收藏的人物").font(.title3)
        Spacer()
        NavigationLink(value: NavDestination.userMono(user.slim)) {
          Text("更多 »")
            .font(.caption)
        }.buttonStyle(.navLink)
      }
      .padding(.top, 8)
      .task(refresh)
      Divider()

      LazyVGrid(columns: columns) {
        ForEach(persons) { person in
          ImageView(img: person.images?.resize(.r200))
            .imageStyle(width: 60, height: 60)
            .imageType(.person)
            .imageLink(person.link)
        }
      }
    }.animation(.default, value: persons)
  }
}
