import SwiftUI

struct ImageViewStyle {
  let width: CGFloat?
  let height: CGFloat?
  let cornerRadius: CGFloat
  let alignment: Alignment
}

struct ImageViewStyleKey: EnvironmentKey {
  static let defaultValue = ImageViewStyle(
    width: nil, height: nil, cornerRadius: 5, alignment: .top)
}

extension EnvironmentValues {
  var imageStyle: ImageViewStyle {
    get { self[ImageViewStyleKey.self] }
    set { self[ImageViewStyleKey.self] = newValue }
  }
}

extension View {
  func imageStyle(
    width: CGFloat? = nil, height: CGFloat? = nil, cornerRadius: CGFloat = 5,
    alignment: Alignment = .top
  )
    -> some View
  {
    let style = ImageViewStyle(
      width: width, height: height, cornerRadius: cornerRadius, alignment: alignment)
    return self.environment(\.imageStyle, style)
  }
}
