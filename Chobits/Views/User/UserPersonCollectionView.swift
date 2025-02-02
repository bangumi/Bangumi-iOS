import SwiftUI

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

  var limit: Int {
    if columnCount >= 7 {
      return min(columnCount, 20)
    } else if columnCount >= 4 {
      return columnCount * 2
    } else {
      return columnCount * 3
    }
  }

  var columns: [GridItem] {
    Array(repeating: .init(.flexible()), count: columnCount)
  }

  func refresh() async {
    if width == 0 { return }
    do {
      let resp = try await Chii.shared.getUserPersonCollections(
        username: user.username, limit: 20)
      persons = resp.data
    } catch {
      Notifier.shared.alert(error: error)
    }
  }

  var body: some View {
    VStack {
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
        .onChange(of: width) {
          if !persons.isEmpty {
            return
          }
          Task {
            await refresh()
          }
        }
        Divider()
      }

      LazyVGrid(columns: columns) {
        ForEach(Array(persons.prefix(limit))) { person in
          ImageView(img: person.images?.resize(.r200))
            .imageStyle(width: 60, height: 60)
            .imageType(.person)
            .imageLink(person.link)
        }
      }
    }.animation(.default, value: persons)
  }
}
