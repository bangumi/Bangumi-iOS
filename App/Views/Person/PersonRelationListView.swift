import SwiftUI

struct PersonRelationListView: View {
  let personId: Int

  @State private var reloader = false

  func load(limit: Int, offset: Int) async -> PagedDTO<PersonRelationDTO>? {
    do {
      let resp = try await PersonService.getPersonRelations(
        personId, limit: limit, offset: offset)
      return resp
    } catch {
      Notifier.shared.alert(error: error)
    }
    return nil
  }

  var body: some View {
    ScrollView {
      OffsetPagedView<PersonRelationDTO, _>(reloader: reloader, nextPageFunc: load) { item in
        PersonRelationItemView(item: item)
      }
      .padding(8)
    }
    .navigationTitle("关联人物")
    .navigationBarTitleDisplayMode(.inline)
  }
}

#Preview {
  NavigationStack {
    PersonRelationListView(personId: Person.preview.personId)
  }
}
