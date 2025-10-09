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
          NavigationLink(value: NavDestination.userIndex(user.slim)) {
            Text("目录").font(.title3)
          }.buttonStyle(.navigation)
          Spacer()
        }
        .padding(.top, 8)
        .task(refresh)
        Divider()
      }

      ForEach(indexes) { index in
        VStack {
          IndexItemView(index: index)
          Divider()
        }
      }
    }.animation(.default, value: indexes)
  }
}
