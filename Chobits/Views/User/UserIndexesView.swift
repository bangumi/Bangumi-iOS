import SwiftUI

struct UserIndexesView: View {

  @Environment(User.self) var user

  @State private var indexes: [SlimIndexDTO] = []

  func refresh() async {
    do {
      let resp = try await Chii.shared.getUserIndexes(
        username: user.username, limit: 5)
      indexes = resp.data
    } catch {
      Notifier.shared.alert(error: error)
    }
  }

  var body: some View {
    VStack {
      VStack(spacing: 2) {
        HStack(alignment: .bottom) {
          Text("目录").font(.title3)
          Spacer()
          NavigationLink(value: NavDestination.userIndex(user.slim)) {
            Text("更多 »")
              .font(.caption)
          }.buttonStyle(.navigation)
        }
        .padding(.top, 8)
        .task(refresh)
        Divider()
      }

      ForEach(indexes) { index in
        VStack(alignment: .leading) {
          Text(index.title.withLink(index.link))
          HStack {
            Text("\(index.total) 个条目")
              .foregroundStyle(.secondary)
            Spacer()
            Text("创建于: \(index.createdAt.datetimeDisplay)")
              .foregroundStyle(.secondary)
          }
          .font(.footnote)
          Divider()
        }
      }
    }.animation(.default, value: indexes)
  }
}
