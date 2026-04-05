import BBCode
import Flow
import SwiftUI

struct ReactionsView: View {
  let type: ReactionType
  @Binding var reactions: [ReactionDTO]

  @AppStorage("profile") var profile: Profile = Profile()
  @AppStorage("isAuthenticated") var isAuthenticated: Bool = false
  @AppStorage("enableReactions") var enableReactions: Bool = true

  @State private var updating = false

  func shadowColor(_ reaction: ReactionDTO) -> Color {
    if reaction.users.contains(where: { $0.id == profile.id }) {
      return .linkText.opacity(0.8)
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
      updating = true
      do {
        if reaction.users.contains(where: { $0.id == profile.id }) {
          try await Chii.shared.unlike(path: type.path)
          onDelete()
        } else {
          try await Chii.shared.like(path: type.path, value: reaction.value)
          onAdd(reaction.value)
        }
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
      } catch {
        Notifier.shared.alert(error: error)
      }
      updating = false
    }
  }

  func onAdd(_ value: Int) {
    var updatedReactions = reactions
    for i in 0..<updatedReactions.count {
      if updatedReactions[i].value == value {
        if !updatedReactions[i].users.contains(where: { $0.id == profile.id }) {
          updatedReactions[i].users.append(profile.simple)
        }
      } else {
        updatedReactions[i].users.removeAll(where: { $0.id == profile.id })
      }
    }
    if !updatedReactions.contains(where: { $0.value == value }) {
      updatedReactions.append(ReactionDTO(users: [profile.simple], value: value))
    }
    updatedReactions = updatedReactions.filter { !$0.users.isEmpty }
    withAnimation(.default) {
      reactions = updatedReactions
    }
  }

  func onDelete() {
    var updatedReactions = reactions
    for i in 0..<updatedReactions.count {
      updatedReactions[i].users.removeAll(where: { $0.id == profile.id })
    }
    updatedReactions = updatedReactions.filter { !$0.users.isEmpty }
    withAnimation(.default) {
      reactions = updatedReactions
    }
  }

  var body: some View {
    if enableReactions, !reactions.isEmpty {
      HFlow {
        ForEach(reactions, id: \.value) { reaction in
          Button {
            onClick(reaction)
          } label: {
            CardView(padding: 2, cornerRadius: 10, shadow: shadowColor(reaction)) {
              HStack(alignment: .center, spacing: 4) {
                SmileyReactionImage(code: reaction.smileyCode, size: 16)
                Text("\(reaction.users.count)")
                  .font(.callout)
                  .monospacedDigit()
                  .foregroundStyle(textColor(reaction))
              }.padding(.horizontal, 4)
            }
          }
          .buttonStyle(.plain)
          .disabled(!isAuthenticated || updating)
          .contextMenu {
            ForEach(reaction.users, id: \.id) { user in
              NavigationLink(value: NavDestination.user(user.username)) {
                Text(user.nickname)
              }.buttonStyle(.scale)
            }
          }
        }
      }.animation(.default, value: reactions)
    } else {
      EmptyView()
    }
  }
}

struct ReactionButton: View {
  let type: ReactionType
  @Binding var reactions: [ReactionDTO]
  var showLabel: Bool = false
  var labelText: String = "贴贴"

  @AppStorage("profile") var profile: Profile = Profile()
  @AppStorage("isAuthenticated") var isAuthenticated: Bool = false
  @AppStorage("enableReactions") var enableReactions: Bool = true

  @State private var showPopover = false
  @State private var updating = false

  var columns: [GridItem] {
    Array(repeating: GridItem(.flexible()), count: 4)
  }

  func onClick(_ value: Int) {
    Task {
      updating = true
      do {
        try await Chii.shared.like(path: type.path, value: value)
        showPopover = false
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        onAdd(value)
      } catch {
        Notifier.shared.alert(error: error)
      }
      updating = false
    }
  }

  func onAdd(_ value: Int) {
    var updatedReactions = reactions
    for i in 0..<updatedReactions.count {
      if updatedReactions[i].value == value {
        if !updatedReactions[i].users.contains(where: { $0.id == profile.id }) {
          updatedReactions[i].users.append(profile.simple)
        }
      } else {
        updatedReactions[i].users.removeAll(where: { $0.id == profile.id })
      }
    }
    if !updatedReactions.contains(where: { $0.value == value }) {
      updatedReactions.append(ReactionDTO(users: [profile.simple], value: value))
    }
    updatedReactions = updatedReactions.filter { !$0.users.isEmpty }
    withAnimation(.default) {
      reactions = updatedReactions
    }
  }

  @ViewBuilder
  var buttonLabel: some View {
    if showLabel {
      Label(labelText, systemImage: "heart")
        .font(.subheadline)
    } else {
      Image(systemName: "heart")
    }
  }

  var body: some View {
    if enableReactions {
      let button = Button {
        showPopover = true
      } label: {
        buttonLabel
      }
      .disabled(!isAuthenticated || updating)
      .popover(isPresented: $showPopover) {
        LazyVGrid(columns: columns) {
          ForEach(type.available, id: \.self) { value in
            Button {
              onClick(value)
            } label: {
              SmileyReactionImage(code: REACTIONS[value] ?? "bgm125", size: 24)
            }.buttonStyle(.explode)
          }
        }
        .disabled(!isAuthenticated || updating)
        .padding()
        .presentationCompactAdaptation(.popover)
      }

      if showLabel {
        button
      } else {
        button.buttonStyle(.explode)
      }
    } else {
      EmptyView()
    }
  }
}

private struct SmileyReactionImage: View {
  let code: String
  let size: CGFloat

  var body: some View {
    if let item = SmileyCatalog.item(for: code) {
      SmileyImageView(item: item, size: size)
    } else {
      Text("(\(code))")
        .font(.caption2)
        .frame(width: size, height: size)
    }
  }
}
