import Foundation
import SDWebImage
import SDWebImageAVIFCoder
import SDWebImageSVGCoder
import SDWebImageWebPCoder

/// Configure image support for the App
func configureImageSupport() {
  // Register SVG coder to SDWebImage coders manager
  let svgCoder = SDImageSVGCoder.shared
  SDImageCodersManager.shared.addCoder(svgCoder)

  let webpCoder = SDImageWebPCoder.shared
  SDImageCodersManager.shared.addCoder(webpCoder)

  let avifCoder = SDImageAVIFCoder.shared
  SDImageCodersManager.shared.addCoder(avifCoder)

  // Global cache settings
  // Limit memory cache to 100MB to prevent OOM on older devices
  SDImageCache.shared.config.maxMemoryCost = 100 * 1024 * 1024
  // Limit disk cache to 1GB
  SDImageCache.shared.config.maxDiskSize = 1000 * 1024 * 1024
  // Enable background decoding
  SDImageCache.shared.config.shouldCacheImagesInMemory = true
}
