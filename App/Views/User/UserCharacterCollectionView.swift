import SwiftUI

struct UserCharacterCollectionView: View {
  @AppStorage("titlePreference") var titlePreference: TitlePreference = .original

  @Bindable var user: User

  @State private var refreshing = false
  @State private var characters: [SlimCharacterDTO] = []

  func refresh() async {
    if refreshing { return }
    refreshing = true
    do {
      let resp = try await Chii.shared.getUserCharacterCollections(
        username: user.username, limit: 20)
      characters = resp.data
    } catch {
      Notifier.shared.alert(error: error)
    }
    refreshing = false
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 2) {
      HStack(alignment: .bottom) {
        NavigationLink(value: NavDestination.userMono(user.slim)) {
          Text("角色").font(.title3)
        }
        .buttonStyle(.navigation)
        .padding(.horizontal, 4)

        Spacer(minLength: 0)
      }
      .padding(.top, 8)
      .task {
        if !characters.isEmpty {
          return
        }
        await refresh()
      }
      Divider()

      if refreshing {
        HStack {
          Spacer()
          ProgressView().padding()
          Spacer()
        }
      } else {
        ScrollView(.horizontal, showsIndicators: false) {
          LazyHStack(alignment: .top) {
            ForEach(characters) { character in
              VStack {
                ImageView(img: character.images?.resize(.r200))
                  .imageStyle(width: 60, height: 60)
                  .imageType(.person)
                  .imageNavLink(character.link)
                  .shadow(radius: 2)
                Text(character.title(with: titlePreference))
                  .font(.caption2)
                  .lineLimit(2)
                  .multilineTextAlignment(.leading)
              }.frame(width: 64)
            }
          }.padding(2)
        }
      }
    }
    .animation(.default, value: refreshing)
    .animation(.default, value: characters)
  }
}
