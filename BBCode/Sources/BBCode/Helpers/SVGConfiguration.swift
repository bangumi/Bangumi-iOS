import Foundation
import SDWebImageSVGCoder

/// 配置 SVG 图片支持
public func configureSVGSupport() {
    // 注册 SVG coder 到 SDWebImage coders manager
    let svgCoder = SDImageSVGCoder.shared
    SDImageCodersManager.shared.addCoder(svgCoder)
}
