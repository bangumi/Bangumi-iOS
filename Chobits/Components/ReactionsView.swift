import SwiftUI

struct ReactionsView: View {
  let type: ReactionType
  let reactions: [ReactionDTO]
  let onAdd: (Int) -> Void
  let onDelete: (Int) -> Void

  @AppStorage("profile") var profile: Profile = Profile()

  func shadowColor(_ reaction: ReactionDTO) -> Color {
    if reaction.users.contains(where: { $0.id == profile.id }) {
      return .linkText.opacity(0.5)
    }
    return .black.opacity(0.2)
  }

  func textColor(_ reaction: ReactionDTO) -> Color {
    if reaction.users.contains(where: { $0.id == profile.id }) {
      return .linkText
    }
    return .secondary
  }

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
          CardView(padding: 2, cornerRadius: 10, shadow: shadowColor(reaction)) {
            HStack(spacing: 4) {
              Image(reaction.icon)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 16, height: 16)
              Text("\(reaction.users.count)")
                .font(.callout)
                .foregroundStyle(textColor(reaction))
            }.padding(.horizontal, 4)
          }
        }.buttonStyle(.plain)
      }
    }
  }
}

struct ReactionButton: View {
  let type: ReactionType
  let onAdd: (Int) -> Void
  let onDelete: (Int) -> Void

  @AppStorage("profile") var profile: Profile = Profile()

  @State private var showPopover = false

  var columns: [GridItem] {
    Array(repeating: GridItem(.flexible()), count: 4)
  }

  var body: some View {
    Button {
      showPopover = true
    } label: {
      Image(systemName: "heart")
        .foregroundStyle(.secondary)
    }
    .buttonStyle(.plain)
    .popover(isPresented: $showPopover) {
      LazyVGrid(columns: columns) {
        ForEach(type.available, id: \.self) { value in
          Button {
            print("reaction: \(value)")
          } label: {
            Image(REACTIONS[value] ?? "bgm125")
              .resizable()
              .aspectRatio(contentMode: .fit)
              .frame(width: 24, height: 24)
          }.buttonStyle(.plain)
        }
      }
      .padding()
      .presentationCompactAdaptation(.popover)
    }
  }
}
