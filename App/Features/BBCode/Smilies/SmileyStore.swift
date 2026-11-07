import SDWebImage
import UIKit

struct BBCodeSmileyResource: Sendable {
  let image: UIImage
  let data: Data?
}

@MainActor
final class BangumiSmileyStore {
  static let shared = BangumiSmileyStore()

  private let cache: SDImageCache
  private let manager: SDWebImageManager

  var imageContext: [SDWebImageContextOption: Any] {
    [.customManager: manager]
  }

  private init() {
    let config = SDImageCacheConfig()
    // Downloaded smileys survive app launches and do not inherit the shared
    // image cache's one-week expiry. The size cap still bounds disk usage.
    config.maxDiskAge = -1
    config.maxDiskSize = 128 * 1024 * 1024
    config.maxMemoryCost = 32 * 1024 * 1024
    let cache = SDImageCache(
      namespace: "BangumiSmileys",
      diskCacheDirectory: nil,
      config: config
    )
    self.cache = cache
    self.manager = SDWebImageManager(cache: cache, loader: SDWebImageDownloader.shared)
  }

  func load(
    _ item: BBCodeSmileyItem,
    domains: BangumiDomains
  ) async -> BBCodeSmileyResource? {
    let url = item.remoteURL(domains: domains)
    return await withCheckedContinuation { continuation in
      manager.loadImage(
        with: url,
        options: [.retryFailed, .queryMemoryData, .waitStoreCache],
        progress: nil
      ) { image, data, _, _, finished, _ in
        guard finished else { return }
        guard let image else {
          continuation.resume(returning: nil)
          return
        }
        continuation.resume(
          returning: BBCodeSmileyResource(image: image, data: data)
        )
      }
    }
  }
}
