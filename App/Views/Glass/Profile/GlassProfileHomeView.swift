import SwiftUI

struct GlassProfileHomeView: View {
  let profile: Profile

  @Environment(\.theme) private var theme

  private let sectionTypes: [SubjectType] = [.anime, .book, .music, .game, .real]

  var body: some View {
    ScrollView(showsIndicators: false) {
      VStack(alignment: .leading, spacing: theme.metrics.listSpacing) {
        GlassProfileHeader(profile: profile, isAuthenticated: true)
        GlassPagesMenuCard(user: profile.user)
        ForEach(sectionTypes) { stype in
          GlassCollectionSection(stype: stype)
        }
      }
      .padding(.horizontal, theme.metrics.screenPadding)
      .padding(.top, 8)
      .padding(.bottom, 26)
    }
    .navigationTitle("我的")
    .navigationBarTitleDisplayMode(.inline)
    .toolbar {
      ToolbarItem(placement: .topBarTrailing) {
        Menu {
          NavigationLink(value: NavDestination.profilePrivacy) {
            Label("隐私设置", systemImage: "hand.raised")
          }
          NavigationLink(value: NavDestination.export) {
            Label("导出收藏", systemImage: "square.and.arrow.up")
          }
          NavigationLink(value: NavDestination.settings) {
            Label("设置", systemImage: "gearshape")
          }
        } label: {
          ToolbarCircle {
            Image(systemName: "gearshape")
              .accessibilityLabel("设置与更多")
          }
        }
      }
    }
  }
}
