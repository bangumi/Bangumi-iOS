import Foundation

enum SearchHistory {
  static let limit = 20

  static func record(_ query: String) {
    let keyword = query.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !keyword.isEmpty else { return }
    var history = AppConfig.searchHistory
    history.removeAll { $0 == keyword }
    history.insert(keyword, at: 0)
    if history.count > limit {
      history = Array(history.prefix(limit))
    }
    AppConfig.searchHistory = history
  }

  static func remove(_ query: String) {
    var history = AppConfig.searchHistory
    history.removeAll { $0 == query }
    AppConfig.searchHistory = history
  }

  static func clear() {
    AppConfig.searchHistory = []
  }
}
