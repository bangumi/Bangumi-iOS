import SwiftUI

struct PostStateView: View {
  let state: PostState

  init(_ state: PostState) {
    self.state = state
  }

  var body: some View {
    Text(state.description)
      .padding(.leading, 16)
      .overlay {
        Rectangle()
          .fill(state.color)
          .frame(width: 2)
      }
  }
}
