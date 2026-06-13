import Foundation
import OSLog
import SwiftUI

extension String {
  func withLink(_ link: String?) -> AttributedString {
    var str = AttributedString(self)
    if let url = URL(string: link ?? "") {
      str.link = url
      str.foregroundColor = .linkText
    }
    return str
  }
}

extension Int {
  var ratingDescription: String {
    let desc: [String: String] = [
      "10": "超神作",
      "9": "神作",
      "8": "力荐",
      "7": "推荐",
      "6": "还行",
      "5": "不过不失",
      "4": "较差",
      "3": "差",
      "2": "很差",
      "1": "不忍直视",
    ]
    return desc["\(self)"] ?? ""
  }
}

extension Float {
  var episodeDisplay: String {
    let roundedTenths = (self * 10).rounded() / 10
    if roundedTenths.truncatingRemainder(dividingBy: 1) == 0 {
      return String(format: "%02.0f", roundedTenths)
    }
    return String(format: "%04.1f", roundedTenths)
  }

  var rateDisplay: String {
    String(format: "%.1f", self)
  }
}

extension Array: @retroactive RawRepresentable where Element: Codable {
  public init?(rawValue: String) {
    guard let data = rawValue.data(using: .utf8),
      let result = try? JSONDecoder().decode([Element].self, from: data)
    else { return nil }
    self = result
  }

  public var rawValue: String {
    guard let data = try? JSONEncoder().encode(self),
      let result = String(data: data, encoding: .utf8)
    else {
      return "[]"
    }
    return result
  }
}

extension Array where Element: Identifiable {
  func mergedById(with newData: [Element]) -> [Element] {
    if newData.isEmpty {
      return self
    }
    var result = self
    result.reserveCapacity(result.count + newData.count)
    var indexById: [Element.ID: Int] = [:]
    indexById.reserveCapacity(result.count + newData.count)
    for (idx, item) in result.enumerated() {
      indexById[item.id] = idx
    }
    for item in newData {
      if let idx = indexById[item.id] {
        result[idx] = item
      } else {
        indexById[item.id] = result.count
        result.append(item)
      }
    }
    return result
  }
}

extension Color {
  init(hex: Int, opacity: Double = 1) {
    self.init(
      .sRGB,
      red: Double((hex >> 16) & 0xff) / 255,
      green: Double((hex >> 08) & 0xff) / 255,
      blue: Double((hex >> 00) & 0xff) / 255,
      opacity: opacity
    )
  }

  init?(_ color: String) {
    var color = color.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

    // check for hex color
    if color.hasPrefix("#") {
      color = String(color.dropFirst())
    }

    // handle 3-digit hex color
    if color.count == 3, let hex = Int(color, radix: 16) {
      let r = (hex >> 8) & 0xf
      let g = (hex >> 4) & 0xf
      let b = hex & 0xf
      // convert to 6-digit by repeating each digit
      let fullHex = (r << 20) | (r << 16) | (g << 12) | (g << 8) | (b << 4) | b
      self.init(hex: fullHex)
      return
    }

    // handle 6-digit hex color
    guard color.count == 6, let hex = Int(color, radix: 16) else { return nil }
    self.init(hex: hex)
  }
}

extension Int {
  var date: Date {
    return Date(timeIntervalSince1970: TimeInterval(self))
  }

  var dateDisplay: String {
    return self.date.formatted(date: .numeric, time: .omitted)
  }

  var datetimeDisplay: String {
    return self.date.formatted(date: .numeric, time: .shortened)
  }

  var relativeText: Text {
    // < 7 days
    let relative = -self.date.timeIntervalSinceNow
    if relative < 604800 {
      return Text("\(self.date, style: .relative)前").monospacedDigit()
    } else {
      return Text(self.date.formatted(date: .numeric, time: .shortened))
    }
  }
}

private let safeParseDateCalendar: Calendar = {
  var calendar = Calendar(identifier: .gregorian)
  calendar.timeZone = TimeZone(secondsFromGMT: 0) ?? .gmt
  return calendar
}()

private let safeParseDateFallback = Date(timeIntervalSince1970: 0)

private func validatedDate(year: Int, month: Int, day: Int) -> Date? {
  let components = DateComponents(year: year, month: month, day: day)
  guard let date = safeParseDateCalendar.date(from: components) else {
    return nil
  }
  let resolved = safeParseDateCalendar.dateComponents([.year, .month, .day], from: date)
  guard resolved.year == year, resolved.month == month, resolved.day == day else {
    return nil
  }
  return date
}

func safeParseDate(str: String?) -> Date {
  guard let str = str else {
    return safeParseDateFallback
  }
  let trimmed = str.trimmingCharacters(in: .whitespacesAndNewlines)
  if trimmed.isEmpty {
    return safeParseDateFallback
  }

  if trimmed.count == 10,
    trimmed[trimmed.index(trimmed.startIndex, offsetBy: 4)] == "-",
    trimmed[trimmed.index(trimmed.startIndex, offsetBy: 7)] == "-"
  {
    let year = Int(trimmed.prefix(4))
    let monthStart = trimmed.index(trimmed.startIndex, offsetBy: 5)
    let monthEnd = trimmed.index(monthStart, offsetBy: 2)
    let dayStart = trimmed.index(trimmed.startIndex, offsetBy: 8)
    let month = Int(trimmed[monthStart..<monthEnd])
    let day = Int(trimmed[dayStart...])
    if let year, let month, let day,
      let date = validatedDate(year: year, month: month, day: day)
    {
      return date
    }
  }

  if trimmed.count == 4,
    let year = Int(trimmed),
    let date = safeParseDateCalendar.date(from: DateComponents(year: year))
  {
    return date
  }

  // fallback to 1970-01-01
  return safeParseDateFallback
}

func safeParseRFC3339Date(str: String?) -> Date {
  guard let str = str else {
    return Date(timeIntervalSince1970: 0)
  }
  if str.isEmpty {
    return Date(timeIntervalSince1970: 0)
  }

  let RFC3339DateFormatter = DateFormatter()
  RFC3339DateFormatter.locale = Locale(identifier: "en_US_POSIX")
  RFC3339DateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZZZZZ"
  RFC3339DateFormatter.timeZone = TimeZone(secondsFromGMT: 0)

  if let date = RFC3339DateFormatter.date(from: str) {
    return date
  } else {
    // fallback to 1970-01-01
    return Date(timeIntervalSince1970: 0)
  }
}
