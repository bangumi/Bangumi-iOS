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
    let formatter = NumberFormatter()
    formatter.minimumFractionDigits = 0
    formatter.maximumFractionDigits = 1
    formatter.minimumIntegerDigits = 2
    return formatter.string(from: NSNumber(value: self)) ?? ""
  }

  var rateDisplay: String {
    String(format: "%.1f", self)
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
}

extension Date {
  var formatCollectionDate: String {
    if self.timeIntervalSince1970 <= 0 {
      return ""
    }
    return self.formatted(date: .numeric, time: .shortened)
  }

  var formatRelative: String {
    let timeInterval = -self.timeIntervalSinceNow
    if timeInterval < 60 {
      return "刚刚"
    } else if timeInterval < 3600 {
      let minutes = Int(timeInterval) / 60
      return "\(minutes)分钟前"
    } else if timeInterval < 86400 {  // Within 24 hours
      let hours = Int(timeInterval) / 3600
      let minutes = Int(timeInterval) % 3600 / 60
      return "\(hours)小时\(minutes)分钟前"
    } else if timeInterval < 604800 {  // Within 7 days
      let days = Int(timeInterval) / 86400
      let hours = Int(timeInterval) % 86400 / 3600
      return "\(days)天\(hours)小时前"
    } else {
      return self.formatted(date: .numeric, time: .shortened)
    }
  }
}

extension Int {
  var dateDisplay: String {
    let date = Date(timeIntervalSince1970: TimeInterval(self))
    return date.formatted(date: .numeric, time: .omitted)
  }

  var datetimeDisplay: String {
    let date = Date(timeIntervalSince1970: TimeInterval(self))
    return date.formatted(date: .numeric, time: .shortened)
  }

  var relativeDateDisplay: String {
    let t = Date(timeIntervalSince1970: TimeInterval(self))
    return t.formatRelative
  }
}

func safeParseDate(str: String?) -> Date {
  guard let str = str else {
    return Date(timeIntervalSince1970: 0)
  }
  if str.isEmpty {
    return Date(timeIntervalSince1970: 0)
  }
  if str == "2099" {
    return Date(timeIntervalSince1970: 0)
  }

  let dateFormatter = DateFormatter()
  dateFormatter.locale = Locale(identifier: "en_US_POSIX")
  dateFormatter.dateFormat = "yyyy-MM-dd"
  dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)

  if let date = dateFormatter.date(from: str) {
    return date
  } else {
    Logger.app.warning("failed to parse date: \(str)")
    return Date(timeIntervalSince1970: 0)
  }
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
    Logger.app.warning("failed to parse RFC3339 date: \(str)")
    return Date(timeIntervalSince1970: 0)
  }
}
