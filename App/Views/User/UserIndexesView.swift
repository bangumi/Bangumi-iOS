import SwiftUI

struct UserIndexesView: View {

  let user: UserDTO

  @State private var indexes: [SlimIndexDTO] = []

  func refresh() async {
    do {
      let resp = try await UserService.getUserIndexes(
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
        IndexItemView(index: index)
      }
    }.animation(.default, value: indexes)
  }
}
