import SwiftUI

public enum ImageType: String, Sendable {
  case common
  case subject
  case person
  case avatar
  case photo
  case icon
}

struct ImageTypeKey: EnvironmentKey {
  static let defaultValue = ImageType.common
}

extension EnvironmentValues {
  var imageType: ImageType {
    get { self[ImageTypeKey.self] }
    set { self[ImageTypeKey.self] = newValue }
  }
}

extension View {
  public func imageType(_ type: ImageType) -> some View {
    self.environment(\.imageType, type)
  }
}
