import CryptoKit
import SwiftUI

struct AnonymizationHelper {
  /// Generates a consistent hash string from topic ID and user ID
  /// - Parameters:
  ///   - topicId: The topic ID
  ///   - userId: The user ID
  /// - Returns: First 8 characters of the SHA256 hash
  static func generateHash(topicId: Int, userId: Int) -> String {
    let input = "\(topicId)-\(userId)"
    let hash = SHA256.hash(data: Data(input.utf8))
    let hashString = hash.compactMap { String(format: "%02x", $0) }.joined()
    return String(hashString.prefix(8)).uppercased()
  }

  /// Generates a deterministic solid color from a hash string
  /// - Parameter hash: The hash string to generate color from
  /// - Returns: A SwiftUI Color
  static func generateColor(from hash: String) -> Color {
    let components = colorComponents(from: hash)
    return Color(
      hue: components.hue,
      saturation: components.saturation,
      brightness: components.brightness
    )
  }

  static func generateCSSColor(from hash: String) -> String {
    let components = colorComponents(from: hash)
    let hueSector = components.hue * 6
    let sector = Int(floor(hueSector)) % 6
    let fraction = hueSector - floor(hueSector)
    let p = components.brightness * (1 - components.saturation)
    let q = components.brightness * (1 - fraction * components.saturation)
    let t = components.brightness * (1 - (1 - fraction) * components.saturation)
    let rgb: (Double, Double, Double)
    switch sector {
    case 0:
      rgb = (components.brightness, t, p)
    case 1:
      rgb = (q, components.brightness, p)
    case 2:
      rgb = (p, components.brightness, t)
    case 3:
      rgb = (p, q, components.brightness)
    case 4:
      rgb = (t, p, components.brightness)
    default:
      rgb = (components.brightness, p, q)
    }

    return String(
      format: "rgb(%.1f%% %.1f%% %.1f%%)",
      locale: Locale(identifier: "en_US_POSIX"),
      rgb.0 * 100,
      rgb.1 * 100,
      rgb.2 * 100
    )
  }

  private static func colorComponents(from hash: String) -> (
    hue: Double,
    saturation: Double,
    brightness: Double
  ) {
    // Use first 6 characters of hash to generate RGB values
    let hexString = String(hash.prefix(6))

    // Convert hex to integer
    var rgb: UInt64 = 0
    Scanner(string: hexString).scanHexInt64(&rgb)

    // Extract RGB components
    let r = Double((rgb >> 16) & 0xFF) / 255.0
    let g = Double((rgb >> 8) & 0xFF) / 255.0
    let b = Double(rgb & 0xFF) / 255.0

    // Convert to HSL and adjust saturation/lightness for better visual variety
    let maxVal = Swift.max(r, g, b)
    let minVal = Swift.min(r, g, b)
    let l = (maxVal + minVal) / 2.0

    var h: Double = 0
    var s: Double = 0

    if maxVal != minVal {
      let d = maxVal - minVal
      s = l > 0.5 ? d / (2.0 - maxVal - minVal) : d / (maxVal + minVal)

      if maxVal == r {
        h = ((g - b) / d + (g < b ? 6.0 : 0.0)) / 6.0
      } else if maxVal == g {
        h = ((b - r) / d + 2.0) / 6.0
      } else {
        h = ((r - g) / d + 4.0) / 6.0
      }
    }

    // Ensure good saturation and lightness for visibility
    let adjustedS = Swift.max(0.5, Swift.min(0.8, s))
    let adjustedL = Swift.max(0.4, Swift.min(0.6, l))

    return (h, adjustedS, adjustedL)
  }
}
