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
      let resp = try await Chii.shared.getUserSubjectCollections(
        username: user.username, type: ctype, subjectType: stype, limit: limit, offset: offset)
      return resp
    } catch {
      Notifier.shared.alert(error: error)
    }
    return nil
  }

  var body: some View {
    VStack {
      Picker("Type", selection: $ctype) {
        ForEach(CollectionType.allTypes(), id: \.self) { ct in
          if let count = ctypes[ct], count > 0 {
            Text("\(ct.description(stype))(\(count))")
              .tag(ct)
          } else {
            Text("\(ct.description(stype))")
              .tag(ct)
          }
        }
      }
      .pickerStyle(.segmented)
      .padding(.horizontal, 8)
      .onChange(of: ctype) { _, _ in
        reloader.toggle()
      }

      ScrollView {
        PageView<SlimSubjectDTO, _>(limit: 20, reloader: reloader, nextPageFunc: load) {
          item in
          UserSubjectCollectionRowView(subject: item)
          Divider()
        }.padding(8)
      }
    }
    .navigationTitle(title)
    .navigationBarTitleDisplayMode(.inline)
  }
}
