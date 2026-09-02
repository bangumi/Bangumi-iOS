import SwiftUI

struct UserIndexesView: View {

  let user: UserDTO

  @Environment(\.theme) private var theme

  @State private var indexes: [SlimIndexDTO] = []

  func refresh() async {
    do {
      let resp = try await UserService.getUserIndexes(
        username: user.username, limit: 5)
      withAnimation(.default) {
        indexes = resp.data
      }
    } catch {
      Notifier.shared.alert(error: error)
    }
  }

  var body: some View {
    VStack {
      VStack(spacing: 2) {
        Group {
          if theme.isClassic {
            HStack(alignment: .bottom) {
              NavigationLink(value: NavDestination.userIndex(user.slim)) {
                Text("目录").font(.title3)
              }.buttonStyle(.navigation)
              Spacer()
            }
          } else {
            ThemedSectionHeader {
              NavigationLink(value: NavDestination.userIndex(user.slim)) {
                Text("目录").font(.title3)
              }.buttonStyle(.navigation)
            }
          }
        }
        .padding(.top, 8)
        .task(refresh)
        ThemedDivider()
      }

      ForEach(indexes) { index in
        IndexItemView(index: index)
      }
    }
  }
}
