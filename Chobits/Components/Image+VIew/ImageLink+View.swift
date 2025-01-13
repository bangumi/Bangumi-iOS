import SwiftUI

extension View {
  func imageLink(_ link: String?) -> some View {
    let url = URL(string: link ?? "") ?? URL(string: "")!
    return Link(destination: url) {
      self
    }.buttonStyle(.plain)
  }
}
