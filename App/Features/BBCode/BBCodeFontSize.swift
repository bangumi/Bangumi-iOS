import Foundation

func clampedBBCodeFontSize(_ rawValue: String) -> Int? {
  guard let size = Int(rawValue.trimmingCharacters(in: .whitespacesAndNewlines)) else {
    return nil
  }

  return min(max(size, 8), 50)
}
