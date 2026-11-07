import SDWebImageSwiftUI
import SwiftUI

public struct BBCodeSmileyImageView: View {
  let item: BBCodeSmileyItem
  let size: CGFloat

  @Environment(\.bangumiDomains) private var domains

  public init(item: BBCodeSmileyItem, size: CGFloat) {
    self.item = item
    self.size = size
  }

  public var body: some View {
    AnimatedImage(
      url: item.remoteURL(domains: domains),
      options: [.retryFailed],
      context: BangumiSmileyStore.shared.imageContext
    ) {
      Text(item.token)
        .font(.caption2)
        .lineLimit(1)
    }
    .resizable()
    .aspectRatio(contentMode: .fit)
    .frame(width: size, height: size)
  }
}
