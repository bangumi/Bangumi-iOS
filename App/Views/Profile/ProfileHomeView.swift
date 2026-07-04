import SwiftUI

struct ProfileHomeView: View {
  @AppStorage("profile") var profile: Profile = Profile()

  var body: some View {
    ScrollView(showsIndicators: false) {
      VStack(alignment: .leading, spacing: 10) {
        ProfileHeaderView(profile: profile, isAuthenticated: true)
          .padding(.top, 12)
          .padding(.bottom, 8)
          .frame(maxWidth: .infinity)

        ForEach(SubjectType.allTypes) { stype in
          CollectionSubjectTypeView(stype: stype)
            .padding(.top, 5)
        }
      }.padding(.horizontal, 8)
    }
    .navigationTitle("我的收藏")
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
        } label: {
          Image(systemName: "ellipsis")
        }
      }
    }
  }
}
