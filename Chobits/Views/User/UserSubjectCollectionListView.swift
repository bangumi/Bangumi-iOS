import SwiftUI

struct UserSubjectCollectionListView: View {
  let user: SlimUserDTO
  let stype: SubjectType

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

  func load(limit: Int, offset: Int) async -> PagedDTO<SlimUserSubjectCollectionDTO>? {
    do {
      let resp = try await Chii.shared.getUserSubjectCollections(
        username: user.username, type: ctype, subjectType: stype, limit: limit, offset: offset)
      return PagedDTO<SlimUserSubjectCollectionDTO>(
        data: resp.data.map { $0.slim },
        total: resp.total
      )
    } catch {
      Notifier.shared.alert(error: error)
    }
    return nil
  }

  var body: some View {
    VStack {
      Picker("Type", selection: $ctype) {
        ForEach(CollectionType.allTypes(), id: \.self) { type in
          Text(type.description(stype)).tag(type)
        }
      }
      .pickerStyle(.segmented)
      .padding(.horizontal, 8)
      .onChange(of: ctype) { _, _ in
        reloader.toggle()
      }

      ScrollView {
        PageView<SlimUserSubjectCollectionDTO, _>(limit: 20, reloader: reloader, nextPageFunc: load)
        {
          item in
          CollectionRowView(collection: item)
          Divider()
        }.padding(8)
      }
    }
    .navigationTitle(title)
    .navigationBarTitleDisplayMode(.inline)
  }
}
