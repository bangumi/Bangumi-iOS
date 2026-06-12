import CoreSpotlight
import OSLog

enum SearchIndexing {
  static func index(_ items: [SearchableItem]) async {
    do {
      try await CSSearchableIndex.default().indexSearchableItems(
        items.filter { $0.identifier > 0 }.map { $0.index() })
    } catch {
      Logger.app.error("Failed to index: \(error)")
    }
  }
}
