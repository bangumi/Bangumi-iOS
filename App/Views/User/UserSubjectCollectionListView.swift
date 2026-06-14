import SwiftUI

struct UserSubjectCollectionListView: View {
  let user: SlimUserDTO
  let stype: SubjectType
  let ctypes: [CollectionType: Int]

  @AppStorage("profile") var profile: Profile = Profile()

  @State private var reloader = false
  @State private var ctype: CollectionType = .collect

  var title: String {
    if user.username == profile.username {
      return "我的\(stype.description)"
    } else {
      return "\(user.nickname)的\(stype.description)"
    }
  }

  func load(limit: Int, offset: Int) async -> PagedDTO<SlimSubjectDTO>? {
    do {
      let resp = try await UserService.getUserSubjectCollections(
        username: user.username, type: ctype, subjectType: stype, limit: limit, offset: offset)
      return resp
    } catch {
      Notifier.shared.alert(error: error)
    }
    return nil
  }

  var body: some View {
    VStack {
      CollectionTypeSegmentedPickerView(subjectType: stype, counts: ctypes, selection: $ctype)
        .onChange(of: ctype) { _, _ in
          reloader.toggle()
        }

      ScrollView {
        OffsetPagedView<SlimSubjectDTO, _>(limit: 20, reloader: reloader, nextPageFunc: load) {
          item in
          SubjectCollectionRowContentView(subject: item)
          Divider()
        }.padding(8)
      }
    }
    .navigationTitle(title)
    .navigationBarTitleDisplayMode(.inline)
  }
}
