import CoreGraphics
import CoreImage
import Foundation
import SwiftUI

// BMO Emoji Renderer
struct BmoRenderer {

  // Render BMO emoji as SwiftUI Image
  @MainActor
  static func renderImage(
    from result: BmoDecoder.BmoResult, size: CGSize? = nil, textSize: Int = 16
  ) -> Image? {
    let emojiSize = size ?? CGSize(width: CGFloat(textSize), height: CGFloat(textSize))
    guard !result.items.isEmpty else {
      return nil
    }

    // Render as CGImage first
    guard let cgImage = renderCGImage(from: result, size: emojiSize) else {
      return nil
    }

    // Convert CGImage to SwiftUI Image
    return Image(cgImage, scale: 1.0, label: Text("BMO Emoji"))
  }

  // Render BMO emoji as CGImage
  static func renderCGImage(
    from result: BmoDecoder.BmoResult, size: CGSize? = nil, textSize: Int = 16
  ) -> CGImage? {
    let emojiSize = size ?? CGSize(width: CGFloat(textSize), height: CGFloat(textSize))
    guard !result.items.isEmpty else {
      return nil
    }

    // Sort items by layer
    let sortedItems = result.items.sorted { $0.layer < $1.layer }

    // Create a bitmap context
    let colorSpace = CGColorSpaceCreateDeviceRGB()
    let bitmapInfo = CGImageAlphaInfo.premultipliedLast.rawValue

    guard
      let context = CGContext(
        data: nil,
        width: Int(emojiSize.width),
        height: Int(emojiSize.height),
        bitsPerComponent: 8,
        bytesPerRow: 0,
        space: colorSpace,
        bitmapInfo: bitmapInfo)
    else {
      return nil
    }

    // Clear background
    context.clear(CGRect(origin: .zero, size: emojiSize))

    // Draw each layer
    for item in sortedItems {
      drawItem(item, in: context, size: emojiSize)
    }

    return context.makeImage()
  }

  // Draw a single BMO item
  private static func drawItem(
    _ item: BmoDecoder.BmoDecodedItem, in context: CGContext, size: CGSize
  ) {
    // Extract filename from src path
    let filename = URL(fileURLWithPath: item.src).lastPathComponent

    // Load the image
    guard let originalImage = loadBmoImage(filename: filename) else {
      return
    }

    // Apply color adjustments first using Core Image
    let processedImage: CGImage
    let h = item.modifiers["h"] as? Int32 ?? 0
    let l = item.modifiers["l"] as? Int32 ?? 50  // Default to 50% lightness
    let s = item.modifiers["s"] as? Int32 ?? 100  // Default to 100% saturation

    if h != 0 || l != 50 || s != 100 {
      processedImage =
        applyColorAdjustmentsToImage(
          originalImage, hue: h, lightness: l, saturation: s
        ) ?? originalImage
    } else {
      processedImage = originalImage
    }

    // Apply modifiers
    let rect = CGRect(origin: .zero, size: size)

    // Apply transformations
    context.saveGState()

    // Apply position offset
    if let x = item.modifiers["x"] as? Int32,
      let y = item.modifiers["y"] as? Int32
    {
      context.translateBy(x: CGFloat(x), y: CGFloat(y))
    }

    // Apply transform mask
    if let tf = item.modifiers["tf"] as? UInt32 {
      applyTransformMask(tf, to: context, size: size)
    }

    // Draw the processed image
    context.draw(processedImage, in: rect)

    context.restoreGState()
  }

  // Load BMO image from bundle
  private static func loadBmoImage(filename: String) -> CGImage? {
    // Try different approaches to find the image
    var url: URL?

    // First try with subdirectory
    url = Bundle.module.url(
      forResource: filename.replacingOccurrences(of: ".png", with: ""),
      withExtension: "png",
      subdirectory: "Bmo")

    // If not found, try without subdirectory
    if url == nil {
      url = Bundle.module.url(
        forResource: filename.replacingOccurrences(of: ".png", with: ""),
        withExtension: "png")
    }

    guard let imageUrl = url,
      let imageSource = CGImageSourceCreateWithURL(imageUrl as CFURL, nil),
      let image = CGImageSourceCreateImageAtIndex(imageSource, 0, nil)
    else {
      return nil
    }
    return image
  }

  // Apply transform mask
  private static func applyTransformMask(_ mask: UInt32, to context: CGContext, size: CGSize) {
    let flipH = (mask & 1) != 0
    let flipV = (mask & 2) != 0
    let rotation = ((mask >> 2) & 3) * 90

    // Apply flips
    if flipH {
      context.scaleBy(x: -1, y: 1)
      context.translateBy(x: -size.width, y: 0)
    }

    if flipV {
      context.scaleBy(x: 1, y: -1)
      context.translateBy(x: 0, y: -size.height)
    }

    // Apply rotation
    if rotation != 0 {
      context.translateBy(x: size.width / 2, y: size.height / 2)
      context.rotate(by: CGFloat(rotation) * .pi / 180)
      context.translateBy(x: -size.width / 2, y: -size.height / 2)
    }
  }

  // Apply color adjustments to image using Core Image
  private static func applyColorAdjustmentsToImage(
    _ image: CGImage, hue: Int32, lightness: Int32, saturation: Int32
  ) -> CGImage? {
    // Convert HSL values to normalized values
    // Hue: 0-360 degrees -> 0-1 (normalized)
    let h = CGFloat(hue) / 360.0
    // Saturation: 0-100% -> 0-1 (normalized)
    let s = CGFloat(saturation) / 100.0
    // Lightness: 0-100% -> 0-1 (normalized)
    let l = CGFloat(lightness) / 100.0

    // Create Core Image context
    let ciContext = CIContext()

    // Convert CGImage to CIImage
    let ciImage = CIImage(cgImage: image)

    var processedImage = ciImage

    // Apply hue adjustment
    if h != 0 {
      let hueFilter = CIFilter(name: "CIHueAdjust")
      hueFilter?.setValue(processedImage, forKey: kCIInputImageKey)
      // Convert normalized hue to radians for Core Image
      hueFilter?.setValue(h * 2 * .pi, forKey: kCIInputAngleKey)
      if let output = hueFilter?.outputImage {
        processedImage = output
      }
    }

    // Apply saturation adjustment
    if s != 1.0 {
      let saturationFilter = CIFilter(name: "CIColorControls")
      saturationFilter?.setValue(processedImage, forKey: kCIInputImageKey)
      saturationFilter?.setValue(s, forKey: kCIInputSaturationKey)
      if let output = saturationFilter?.outputImage {
        processedImage = output
      }
    }

    // Apply brightness adjustment (lightness)
    if l != 1.0 {
      let brightnessFilter = CIFilter(name: "CIColorControls")
      brightnessFilter?.setValue(processedImage, forKey: kCIInputImageKey)
      // Convert lightness to brightness: lightness 0.5 = no change, 0 = black, 1 = white
      let brightness = (l - 0.5) * 2.0  // Map 0-1 to -1 to 1
      brightnessFilter?.setValue(brightness, forKey: kCIInputBrightnessKey)
      if let output = brightnessFilter?.outputImage {
        processedImage = output
      }
    }

    // Convert back to CGImage
    return ciContext.createCGImage(processedImage, from: processedImage.extent)
  }
}
