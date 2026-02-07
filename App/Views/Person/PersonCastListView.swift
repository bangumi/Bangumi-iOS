import SwiftData
import SwiftUI

struct PersonCastListView: View {
  let personId: Int

  @State private var type: CastType = .none
  @State private var reloader = false

  func load(limit: Int, offset: Int) async -> PagedDTO<PersonCastDTO>? {
    do {
      let resp = try await Chii.shared.getPersonCasts(
        personId, type: type.rawValue, limit: limit, offset: offset)
      return resp
    } catch {
      Notifier.shared.alert(error: error)
    }
    return nil
  }

  var body: some View {
    Picker("Cast Type", selection: $type) {
      ForEach(CastType.allCases) { ct in
        Text(ct.description).tag(ct)
      }
    }
    .padding(.horizontal, 8)
    .pickerStyle(.segmented)
    .onChange(of: type) { _, _ in
      reloader.toggle()
    }
    ScrollView {
      PageView<PersonCastDTO, _>(reloader: reloader, nextPageFunc: load) { item in
        PersonCastItemView(item: item)
      }
      .padding(8)
    }
    .buttonStyle(.navigation)
    .navigationTitle("出演角色")
    .navigationBarTitleDisplayMode(.inline)
  }
}

#Preview {
  let person = Person.preview
  return PersonCastListView(personId: person.personId)
}
