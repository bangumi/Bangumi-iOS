import SwiftUI

struct PersonIndexListView: View {
  let personId: Int

  @State private var reloader = false

  @Environment(\.theme) private var theme

  func load(limit: Int, offset: Int) async -> PagedDTO<SlimIndexDTO>? {
    do {
      let resp = try await PersonService.getPersonIndexes(
        personId: personId, limit: limit, offset: offset)
      return resp
    } catch {
      Notifier.shared.alert(error: error)
    }
    return nil
  }

  @ViewBuilder
  private var classicBody: some View {
    ScrollView {
      OffsetPagedView<SlimIndexDTO, _>(reloader: reloader, nextPageFunc: load) { item in
        IndexItemView(index: item)
      }.padding(8)
    }
  }

  var body: some View {
    Group {
      if theme.isClassic {
        classicBody
      } else {
        GlassPersonIndexListView(personId: personId)
      }
    }
    .navigationTitle("相关目录")
    .navigationBarTitleDisplayMode(.inline)
  }
}
