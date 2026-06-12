import SwiftUI

extension View {
  func searchInputTraits() -> some View {
    self
      .autocorrectionDisabled()
      .textInputAutocapitalization(.never)
      .submitLabel(.search)
  }
}
