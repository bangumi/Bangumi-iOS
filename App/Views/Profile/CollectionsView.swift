import SwiftUI

struct CollectionsView: View {
  @AppStorage("isAuthenticated") var isAuthenticated: Bool = false
  @AppStorage("profile") var profile: Profile = Profile()

  var body: some View {
    ScrollView(showsIndicators: false) {
      VStack(alignment: .leading, spacing: 10) {
        ProfileHeaderView(profile: profile, isAuthenticated: isAuthenticated)
          .padding(.top, 12)
          .padding(.bottom, 8)
          .frame(maxWidth: .infinity)

        if isAuthenticated {
          ForEach(SubjectType.allTypes) { stype in
            CollectionSubjectTypeView(stype: stype)
              .padding(.top, 5)
          }
        } else {
          AuthView(slogan: "请登录 Bangumi 以查看收藏")
            .frame(maxWidth: .infinity)
            .padding(.vertical, 24)
        }
      }.padding(.horizontal, 8)
    }
    .navigationTitle("我的收藏")
    .navigationBarTitleDisplayMode(.inline)
  }
}
