import SwiftUI

struct ReactionsView: View {
  let type: ReactionType
  @Binding var reactions: [ReactionDTO]

  @AppStorage("profile") var profile: Profile = Profile()
  @AppStorage("isAuthenticated") var isAuthenticated: Bool = false

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

  func onClick(_ reaction: ReactionDTO) {
    Task {
      do {
        if reaction.users.contains(where: { $0.id == profile.id }) {
          try await Chii.shared.unlike(path: type.path)
          onDelete(reaction.value)
        } else {
          try await Chii.shared.like(path: type.path, value: reaction.value)
          onAdd(reaction.value)
        }
      } catch {
        Notifier.shared.alert(error: error)
      }
    }
  }

  func onAdd(_ value: Int) {
    for reaction in reactions {
      if reaction.value == value {
        if !reaction.users.contains(where: { $0.id == profile.id }) {
          var updatedReaction = reaction
          updatedReaction.users.append(profile.simple)
          reactions = reactions.map { $0.value == value ? updatedReaction : $0 }
        }
        return
      } else {
        if reaction.users.contains(where: { $0.id == profile.id }) {
          var updatedReaction = reaction
          updatedReaction.users.removeAll(where: { $0.id == profile.id })
          reactions = reactions.map { $0.value == value ? updatedReaction : $0 }
        }
      }
    }
    reactions.append(ReactionDTO(users: [profile.simple], value: value))
  }

  func onDelete(_ value: Int) {
    for reaction in reactions {
      if reaction.value == value {
        var updatedReaction = reaction
        updatedReaction.users.removeAll(where: { $0.id == profile.id })
        reactions = reactions.map { $0.value == value ? updatedReaction : $0 }
        if updatedReaction.users.isEmpty {
          reactions = reactions.filter { $0.value != value }
        }
        return
      }
    }
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
    }.disabled(!isAuthenticated)
  }
}

struct ReactionButton: View {
  let type: ReactionType
  @Binding var reactions: [ReactionDTO]

  @AppStorage("profile") var profile: Profile = Profile()
  @AppStorage("isAuthenticated") var isAuthenticated: Bool = false

  @State private var showPopover = false

  var columns: [GridItem] {
    Array(repeating: GridItem(.flexible()), count: 4)
  }

  func onClick(_ value: Int) {
    Task {
      do {
        try await Chii.shared.like(path: type.path, value: value)
        onAdd(value)
      } catch {
        Notifier.shared.alert(error: error)
      }
    }
  }

  func onAdd(_ value: Int) {
    for reaction in reactions {
      if reaction.value == value {
        if !reaction.users.contains(where: { $0.id == profile.id }) {
          var updatedReaction = reaction
          updatedReaction.users.append(profile.simple)
          reactions = reactions.map { $0.value == value ? updatedReaction : $0 }
        }
        return
      } else {
        if reaction.users.contains(where: { $0.id == profile.id }) {
          var updatedReaction = reaction
          updatedReaction.users.removeAll(where: { $0.id == profile.id })
          reactions = reactions.map { $0.value == value ? updatedReaction : $0 }
        }
      }
    }
    reactions.append(ReactionDTO(users: [profile.simple], value: value))
  }

  var body: some View {
    Button {
      showPopover = true
    } label: {
      Image(systemName: "heart")
        .foregroundStyle(.secondary)
    }
    .disabled(!isAuthenticated)
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
      .disabled(!isAuthenticated)
      .padding()
      .presentationCompactAdaptation(.popover)
    }
  }
}
