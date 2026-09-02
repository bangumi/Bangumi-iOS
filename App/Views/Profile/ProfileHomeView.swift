import SwiftUI

struct ProfileHomeView: View {
  @AppStorage("profile") var profile: Profile = Profile()

  @Environment(\.theme) private var theme

  var body: some View {
    ScrollView(showsIndicators: false) {
      VStack(alignment: .leading, spacing: theme.isClassic ? 10 : theme.metrics.listSpacing) {
        ProfileHeaderView(profile: profile, isAuthenticated: true)
          .padding(.top, 12)
          .padding(.bottom, 8)
          .frame(maxWidth: .infinity)

        ForEach(SubjectType.allTypes) { stype in
          section(stype)
        }
      }.padding(.horizontal, theme.metrics.screenPadding)
    }
    .navigationTitle("我的")
    .navigationBarTitleDisplayMode(.inline)
    .toolbar {
      ToolbarItemGroup(placement: .topBarTrailing) {
        ProfilePagesMenu(user: profile.user)
        ProfileActionsMenu()
      }
    }
  }

  @ViewBuilder
  private func section(_ stype: SubjectType) -> some View {
    if theme.isClassic {
      CollectionSubjectTypeView(stype: stype)
        .padding(.top, 5)
    } else {
      CardView(padding: theme.metrics.cardPadding) {
        CollectionSubjectTypeView(stype: stype)
      }
    }
  }
}
