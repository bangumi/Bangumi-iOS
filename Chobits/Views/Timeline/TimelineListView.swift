import OSLog
import SwiftData
import SwiftUI

struct TimelineListView: View {
  @State private var reloader = false

  func load(limit: Int, offset: Int) async -> PagedDTO<TimelineDTO>? {
    do {
      let resp = try await Chii.shared.getTimeline(limit: limit, offset: offset)
      return PagedDTO(data: resp, total: 1000)
    } catch {
      Notifier.shared.alert(error: error)
    }
    return nil
  }

  var body: some View {
    PageView<TimelineDTO, _>(reloader: reloader, nextPageFunc: load) { item in
      TimelineItemView(item: item)
    }
  }
}
