import SDWebImageSwiftUI
import SwiftUI

public struct BBCodeSmileyImageView: View {
  let item: BBCodeSmileyItem
  let size: CGFloat

  public init(item: BBCodeSmileyItem, size: CGFloat) {
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
