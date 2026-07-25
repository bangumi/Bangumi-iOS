import Foundation

struct BBCodeMediaDimensions {
  let width: Int
  let height: Int

  init?(rawValue: String) {
    let values = rawValue.split(omittingEmptySubsequences: false) {
      $0 == "," || $0 == "x" || $0 == "X"
    }
    guard values.count == 2,
      let width = Int(values[0].trimmingCharacters(in: .whitespacesAndNewlines)),
      let height = Int(values[1].trimmingCharacters(in: .whitespacesAndNewlines)),
      (1...9999).contains(width),
      (1...9999).contains(height)
    else {
      return nil
    }

    self.width = width
    self.height = height
  }
}
