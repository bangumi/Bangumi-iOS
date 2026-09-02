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
  @AppStorage("titlePreference") var titlePreference: TitlePreference = .original

  @State private var type: MonoType = .character

  @Environment(\.theme) private var theme

  var title: String {
    if user.username == profile.username {
      return "我收藏的\(type.title)"
    } else {
      return "\(user.nickname)收藏的\(type.title)"
    }
  }

  func loadCharacters(limit: Int, offset: Int) async -> PagedDTO<SlimCharacterDTO>? {
    do {
      let resp = try await UserService.getUserCharacterCollections(
        username: user.username, limit: limit, offset: offset)
      return resp
    } catch {
      Notifier.shared.alert(error: error)
    }
    return nil
  }

  func loadPersons(limit: Int, offset: Int) async -> PagedDTO<SlimPersonDTO>? {
    do {
      let resp = try await UserService.getUserPersonCollections(
        username: user.username, limit: limit, offset: offset)
      return resp
    } catch {
      Notifier.shared.alert(error: error)
    }
    return nil
  }

  var body: some View {
    if theme.isClassic {
      classicBody
    } else {
      GlassUserMonoListView(user: user, type: $type)
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
    }
  }

  private var classicBody: some View {
    VStack {
      Picker("Type", selection: $type.animated()) {
        ForEach(MonoType.allCases, id: \.self) { type in
          Text(type.title).tag(type)
        }
      }
      .pickerStyle(.segmented)
      .padding(.horizontal, 8)

      ScrollView {
        switch type {
        case .character:
          OffsetPagedView<SlimCharacterDTO, _>(nextPageFunc: loadCharacters) { item in
            CardView {
              HStack(alignment: .top) {
                ImageView(img: item.images?.resize(.r200))
                  .imageType(.person)
                  .imageStyle(width: 60, height: 60, alignment: .top)
                VStack(alignment: .leading) {
                  Text(item.title(with: titlePreference).withLink(item.link))
                }
                Spacer()
              }
            }
          }.padding(8)
        case .person:
          OffsetPagedView<SlimPersonDTO, _>(nextPageFunc: loadPersons) { item in
            CardView {
              HStack(alignment: .top) {
                ImageView(img: item.images?.resize(.r200))
                  .imageType(.person)
                  .imageStyle(width: 60, height: 60, alignment: .top)
                VStack(alignment: .leading) {
                  Text(item.title(with: titlePreference).withLink(item.link))
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
