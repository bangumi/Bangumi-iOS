import SDWebImageSwiftUI
import SwiftUI

public struct SmileyImageView: View {
  let item: SmileyItem
  let size: CGFloat

  public init(item: SmileyItem, size: CGFloat) {
    self.item = item
    self.size = size
  }

  public var body: some View {
    if let url = item.resourceURL() {
      AnimatedImage(url: url)
        .resizable()
        .aspectRatio(contentMode: .fit)
        .frame(width: size, height: size)
    } else {
      Text(item.token)
        .font(.caption2)
        .frame(width: size, height: size)
    }
  }
}
