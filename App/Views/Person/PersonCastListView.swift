import SwiftUI

struct PersonCastListView: View {
  let personId: Int

  @State private var type: CastType = .none
  @State private var reloader = false

  func load(limit: Int, offset: Int) async -> PagedDTO<PersonCastDTO>? {
    do {
      let resp = try await PersonService.getPersonCasts(
        personId, type: type.rawValue, limit: limit, offset: offset)
      return resp
    } catch {
      Notifier.shared.alert(error: error)
    }
    return nil
  }

  var body: some View {
    Picker("Cast Type", selection: $type.animated()) {
      ForEach(CastType.allCases) { ct in
        Text(ct.description).tag(ct)
      }
    }
    .padding(.horizontal, 8)
    .pickerStyle(.segmented)
    .onChange(of: type) { _, _ in
      withAnimation(.default) {
        reloader.toggle()
      }
    }
    ScrollView {
      OffsetPagedView<PersonCastDTO, _>(reloader: reloader, nextPageFunc: load) { item in
        PersonCastItemView(item: item)
      }
      .padding(8)
    }
    .buttonStyle(.navigation)
    .navigationTitle("出演角色")
    .navigationBarTitleDisplayMode(.inline)
  }
}
