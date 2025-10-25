import Foundation
import SwiftUI

// BMO Emoji Decoder based on the JavaScript reference
struct BmoDecoder {

  // BMO manifest data
  private static let manifestLock = NSLock()
  nonisolated(unsafe) private static var manifest: BmoManifest? = nil

  struct BmoManifest: Codable {
    let face: BmoCategory
    let mouth: BmoCategory
    let eyes: BmoCategory
    let accessories: BmoCategory
    let others: BmoCategory

    struct BmoCategory: Codable {
      let id: String
      let name: String
      let layer: Int
      let multiSelect: Bool
      let maxSelect: Int?
      let items: [BmoItem]

      struct BmoItem: Codable {
        let id: String
        let alias: String?
        let src: String
        let layer: Int
      }
    }
  }

  // Compact flags from the JavaScript reference
  private static let COMPACT_FLAG_TF: UInt32 = 1
  private static let COMPACT_FLAG_H: UInt32 = 2
  private static let COMPACT_FLAG_L: UInt32 = 4
  private static let COMPACT_FLAG_S: UInt32 = 8
  private static let COMPACT_FLAG_X: UInt32 = 16
  private static let COMPACT_FLAG_Y: UInt32 = 32
  private static let COMPACT_FLAG_EXTRA: UInt32 = 64

  struct BmoDecodedItem {
    let id: String
    let src: String
    let layer: Int
    let order: Int
    let category: String
    let modifiers: [String: Any]
    let meta: [String: Any]
  }

  struct BmoResult {
    let raw: String
    let items: [BmoDecodedItem]
    let unknown: [String]
    let options: [String: Any]
  }

  // Load manifest data
  private static func loadManifest() -> BmoManifest? {
    manifestLock.lock()
    defer { manifestLock.unlock() }

    if let manifest = manifest {
      return manifest
    }

    // Try different approaches to find the manifest
    var url: URL?

    // First try with subdirectory
    url = Bundle.module.url(
      forResource: "manifest.local", withExtension: "json", subdirectory: "Bmo")

    // If not found, try without subdirectory
    if url == nil {
      url = Bundle.module.url(forResource: "manifest.local", withExtension: "json")
    }

    guard let manifestUrl = url else {
      return nil
    }

    guard let data = try? Data(contentsOf: manifestUrl),
      let loadedManifest = try? JSONDecoder().decode(BmoManifest.self, from: data)
    else {
      return nil
    }
    manifest = loadedManifest
    return loadedManifest
  }

  // Decode a BMO code string
  static func decode(_ code: String) -> BmoResult {
    let trimmed = code.trimmingCharacters(in: .whitespacesAndNewlines)

    if trimmed.isEmpty {
      return BmoResult(raw: "", items: [], unknown: [], options: [:])
    }

    var workingCode = trimmed

    // Remove parentheses if present
    if workingCode.hasPrefix("(") && workingCode.hasSuffix(")") {
      workingCode = String(workingCode.dropFirst().dropLast())
    }

    // Check if this is a compact BMO code
    if workingCode.hasPrefix("bmoC") {
      return decodeCompact(workingCode)
    }

    // For now, return empty result for non-compact codes
    // In a full implementation, you would decode regular BMO codes here
    return BmoResult(raw: workingCode, items: [], unknown: [workingCode], options: [:])
  }

  // Decode compact BMO code
  private static func decodeCompact(_ code: String) -> BmoResult {
    let original = code.trimmingCharacters(in: .whitespacesAndNewlines)
    var trimmed = original

    if trimmed.isEmpty {
      return BmoResult(raw: "", items: [], unknown: [], options: [:])
    }

    if trimmed.hasPrefix("(") && trimmed.hasSuffix(")") {
      trimmed = String(trimmed.dropFirst().dropLast())
    }

    if !trimmed.hasPrefix("bmoC") {
      return BmoResult(raw: original, items: [], unknown: [original], options: [:])
    }

    let payload = String(trimmed.dropFirst(4))
    if payload.isEmpty {
      return BmoResult(raw: trimmed, items: [], unknown: [], options: [:])
    }

    // Decode base64url
    guard let bytes = decodeBase64Url(payload), !bytes.isEmpty else {
      return BmoResult(raw: trimmed, items: [], unknown: [], options: [:])
    }

    var reader = VarReader(bytes: bytes)
    var resolved: [BmoDecodedItem] = []

    while reader.hasMore() {
      guard let combined = reader.readVarUint() else {
        return BmoResult(raw: trimmed, items: [], unknown: [], options: [:])
      }

      let compactId = combined >> 7
      let flags = combined & 127

      // Look up the actual emoji data from manifest
      guard let manifest = loadManifest(),
        let itemData = findItemByCompactId(compactId, in: manifest)
      else {
        continue
      }

      // Read modifiers based on flags
      var modifiers: [String: Any] = [:]

      if flags & COMPACT_FLAG_TF != 0 {
        if let maskValue = reader.readVarUint() {
          modifiers["tf"] = maskValue & 63
        }
      }

      if flags & COMPACT_FLAG_H != 0 {
        if let hueValue = reader.readVarInt() {
          modifiers["h"] = hueValue
        }
      }

      if flags & COMPACT_FLAG_L != 0 {
        if let lightValue = reader.readVarInt() {
          modifiers["l"] = lightValue
        }
      }

      if flags & COMPACT_FLAG_S != 0 {
        if let saturationValue = reader.readVarInt() {
          modifiers["s"] = saturationValue
        }
      }

      if flags & COMPACT_FLAG_X != 0 {
        if let xValue = reader.readVarInt() {
          modifiers["x"] = xValue
        }
      }

      if flags & COMPACT_FLAG_Y != 0 {
        if let yValue = reader.readVarInt() {
          modifiers["y"] = yValue
        }
      }

      if flags & COMPACT_FLAG_EXTRA != 0 {
        if let extraLength = reader.readVarUint(),
          let extraBytes = reader.readBytes(length: Int(extraLength))
        {
          let extraString = utf8Decode(extraBytes)
          if let extraData = extraString.data(using: .utf8),
            let extraObj = try? JSONSerialization.jsonObject(with: extraData) as? [String: Any]
          {
            for (key, value) in extraObj {
              modifiers[key] = value
            }
          }
        }
      }

      resolved.append(
        BmoDecodedItem(
          id: itemData.id,
          src: itemData.src,
          layer: itemData.layer,
          order: resolved.count,
          category: itemData.category,
          modifiers: modifiers,
          meta: [:]
        ))
    }

    return BmoResult(raw: trimmed, items: resolved, unknown: [], options: [:])
  }

  // Base64url decoding
  private static func decodeBase64Url(_ str: String) -> [UInt8]? {
    var base64 = str.replacingOccurrences(of: "-", with: "+")
      .replacingOccurrences(of: "_", with: "/")

    // Add padding if needed
    while base64.count % 4 != 0 {
      base64 += "="
    }

    guard let data = Data(base64Encoded: base64) else {
      return nil
    }

    return Array(data)
  }

  // UTF-8 decoding
  private static func utf8Decode(_ bytes: [UInt8]) -> String {
    return String(data: Data(bytes), encoding: .utf8) ?? ""
  }
}

// Variable-length integer reader
struct VarReader {
  let bytes: [UInt8]
  var offset: Int = 0

  init(bytes: [UInt8]) {
    self.bytes = bytes
  }

  mutating func readVarUint() -> UInt32? {
    var result: UInt32 = 0
    var shift = 0

    while offset < bytes.count {
      let byte = bytes[offset]
      offset += 1

      result |= UInt32(byte & 127) << shift

      if (byte & 128) == 0 {
        return result
      }

      shift += 7
      if shift > 35 {
        return nil
      }
    }

    return nil
  }

  mutating func readVarInt() -> Int32? {
    guard let encoded = readVarUint() else {
      return nil
    }
    return decodeZigZag(encoded)
  }

  mutating func readBytes(length: Int) -> [UInt8]? {
    if offset + length > bytes.count {
      return nil
    }

    let result = Array(bytes[offset..<offset + length])
    offset += length
    return result
  }

  func hasMore() -> Bool {
    return offset < bytes.count
  }

  // ZigZag decoding
  private func decodeZigZag(_ value: UInt32) -> Int32 {
    let unsigned = UInt32(value)
    let mask = (unsigned & 1) == 1 ? UInt32.max : 0
    let result = (unsigned >> 1) ^ mask

    // Handle the case where the result might be too large for Int32
    // If the result is >= 0x80000000, it represents a negative number
    if result >= 0x8000_0000 {
      return Int32(bitPattern: result)
    } else {
      return Int32(result)
    }
  }
}

// Helper function to find item by compact ID
private func findItemByCompactId(_ compactId: UInt32, in manifest: BmoDecoder.BmoManifest) -> (
  id: String, src: String, layer: Int, category: String
)? {
  var currentId = 0

  // Search through all categories
  let categories = [
    manifest.face, manifest.mouth, manifest.eyes, manifest.accessories, manifest.others,
  ]

  for category in categories {
    for item in category.items {
      if currentId == Int(compactId) {
        return (id: item.id, src: item.src, layer: item.layer, category: category.id)
      }
      currentId += 1
    }
  }

  return nil
}
