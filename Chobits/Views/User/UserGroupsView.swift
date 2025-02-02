import SwiftUI

struct UserGroupsView: View {
  let width: CGFloat

  @Environment(User.self) var user

  @State private var groups: [SlimGroupDTO] = []

  init(_ width: CGFloat) {
    self.width = width
  }

  var columnCount: Int {
    let columns = Int((width - 8) / 110)
    return columns > 0 ? columns : 1
  }

  var limit: Int {
    if columnCount >= 9 {
      return min(columnCount, 20)
    } else if columnCount >= 5 {
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
      let resp = try await Chii.shared.getUserGroups(
        username: user.username, limit: 20)
      groups = resp.data
    } catch {
      Notifier.shared.alert(error: error)
    }
  }

  var body: some View {
    VStack {
      VStack(spacing: 2) {
        HStack(alignment: .bottom) {
          Text("\(user.nickname)加入的小组").font(.title3)
          Spacer()
          NavigationLink(value: NavDestination.userGroup(user.slim)) {
            Text("更多 »")
              .font(.caption)
          }.buttonStyle(.navLink)
        }
        .padding(.top, 8)
        .task(refresh)
        .onChange(of: width) {
          if !groups.isEmpty {
            return
          }
          Task {
            await refresh()
          }
        }
        Divider()
      }

      LazyVGrid(columns: columns) {
        ForEach(Array(groups.prefix(limit))) { group in
          HStack {
            ImageView(img: group.icon?.large)
              .imageStyle(width: 32, height: 32)
              .imageType(.icon)
              .imageLink(group.link)
            VStack(alignment: .leading, spacing: 2) {
              Text(group.title.withLink(group.link))
                .lineLimit(1)
                .font(.footnote)
              Divider()
              Text("\(group.members ?? 0) 位成员")
                .foregroundStyle(.secondary)
                .font(.caption)
                .lineLimit(1)
            }
            Spacer()
          }
        }
      }
    }.animation(.default, value: groups)
  }
}
