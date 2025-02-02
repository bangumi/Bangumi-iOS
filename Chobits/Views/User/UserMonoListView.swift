import SwiftUI

enum MonoType: CaseIterable {
  case character
  case person

  var title: String {
    switch self {
    case .character:
      return "虚构角色"
    case .person:
      return "现实人物"
    }
  }
}

struct UserMonoListView: View {
  let user: SlimUserDTO

  @AppStorage("profile") var profile: Profile = Profile()

  @State private var type: MonoType = .character

  var title: String {
    if user.username == profile.username {
      return "我收藏的\(type.title)"
    } else {
      return "\(user.nickname)收藏的\(type.title)"
    }
  }

  func loadCharacters(limit: Int, offset: Int) async -> PagedDTO<SlimCharacterDTO>? {
    do {
      let resp = try await Chii.shared.getUserCharacterCollections(
        username: user.username, limit: limit, offset: offset)
      return resp
    } catch {
      Notifier.shared.alert(error: error)
    }
    return nil
  }

  func loadPersons(limit: Int, offset: Int) async -> PagedDTO<SlimPersonDTO>? {
    do {
      let resp = try await Chii.shared.getUserPersonCollections(
        username: user.username, limit: limit, offset: offset)
      return resp
    } catch {
      Notifier.shared.alert(error: error)
    }
    return nil
  }

  var body: some View {
    VStack {
      Picker("Type", selection: $type) {
        ForEach(MonoType.allCases, id: \.self) { type in
          Text(type.title).tag(type)
        }
      }
      .pickerStyle(.segmented)
      .padding(.horizontal, 8)

      ScrollView {
        switch type {
        case .character:
          PageView<SlimCharacterDTO, _>(nextPageFunc: loadCharacters) { item in
            CardView {
              HStack(alignment: .top) {
                ImageView(img: item.images?.resize(.r200))
                  .imageType(.person)
                  .imageStyle(width: 60, height: 60)
                VStack(alignment: .leading) {
                  Text(item.name.withLink(item.link))
                  Text(item.nameCN)
                    .foregroundStyle(.secondary)
                    .font(.footnote)
                }
                Spacer()
              }
            }
          }.padding(8)
        case .person:
          PageView<SlimPersonDTO, _>(nextPageFunc: loadPersons) { item in
            CardView {
              HStack(alignment: .top) {
                ImageView(img: item.images?.resize(.r200))
                  .imageType(.person)
                  .imageStyle(width: 60, height: 60)
                VStack(alignment: .leading) {
                  Text(item.name.withLink(item.link))
                  Text(item.nameCN)
                    .foregroundStyle(.secondary)
                    .font(.footnote)
                }
                Spacer()
              }
            }
          }.padding(8)
        }
      }
    }
    .navigationTitle(title)
    .navigationBarTitleDisplayMode(.inline)
  }
}
