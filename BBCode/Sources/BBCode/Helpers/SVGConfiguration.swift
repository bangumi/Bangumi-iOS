import Foundation
import SDWebImageSVGCoder
import SDWebImageWebPCoder
import SDWebImageAVIFCoder

/// 配置图片支持
public func configureImageSupport() {
    // 注册 SVG coder 到 SDWebImage coders manager
    let svgCoder = SDImageSVGCoder.shared
    SDImageCodersManager.shared.addCoder(svgCoder)
    
    let webpCoder = SDImageWebPCoder.shared
    SDImageCodersManager.shared.addCoder(webpCoder)
    
    let avifCoder = SDImageAVIFCoder.shared
    SDImageCodersManager.shared.addCoder(avifCoder)
}
