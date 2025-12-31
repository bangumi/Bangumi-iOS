import SwiftUI

struct RubyView: View {
  let base: String
  let ruby: String
  let fontSize: CGFloat

  init(base: String, ruby: String, fontSize: CGFloat = 16) {
    self.base = base
    self.ruby = ruby
    self.fontSize = fontSize
  }

  var body: some View {
    VStack(alignment: .center, spacing: -2) {
      Text(ruby)
        .font(.system(size: fontSize * 0.5))
        .lineLimit(1)
      Text(base)
        .font(.system(size: fontSize))
    }
    .fixedSize()
  }
}
