import SwiftUI

struct ProfileActionsMenu: View {
  var body: some View {
    Menu {
      NavigationLink(value: NavDestination.profilePrivacy) {
        Label("隐私设置", systemImage: "hand.raised")
      }
      NavigationLink(value: NavDestination.export) {
        Label("导出收藏", systemImage: "square.and.arrow.up")
      }
    } label: {
      Image(systemName: "ellipsis")
    }
  }
}
