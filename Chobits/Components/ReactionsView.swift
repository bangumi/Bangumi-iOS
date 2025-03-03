import SwiftUI

struct ReactionsView: View {
  let type: ReactionType
  let reactions: [ReactionDTO]

  @AppStorage("profile") var profile: Profile = Profile()

  var body: some View {
    HStack {
      ForEach(reactions, id: \.value) { reaction in
        Menu {
          ForEach(reaction.users, id: \.id) { user in
            NavigationLink(value: NavDestination.user(user.username)) {
              Text(user.nickname)
            }.buttonStyle(.plain)
          }
        } label: {
          CardView(padding: 2, cornerRadius: 10) {
            HStack(spacing: 4) {
              Image(reaction.icon)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 18, height: 18)
              Text("\(reaction.users.count)")
                .font(.callout)
                .foregroundStyle(.secondary)
            }.padding(.horizontal, 4)
          }
        }.buttonStyle(.plain)
      }
    }
  }
}

struct ReactionButton: View {
  let type: ReactionType

  var columns: [GridItem] {
    Array(repeating: GridItem(.flexible()), count: 4)
  }

  var body: some View {
    Menu {
      LazyVGrid(columns: columns) {
        ForEach(type.available, id: \.self) { value in
          Button {
            print("reaction")
          } label: {
            Image(REACTIONS[value] ?? "bgm125")
              .resizable()
              .aspectRatio(contentMode: .fit)
              .frame(width: 18, height: 18)
          }.buttonStyle(.plain)
        }
      }
    } label: {
      Image(systemName: "heart")
        .foregroundStyle(.secondary)
    }.buttonStyle(.plain)
  }
}
