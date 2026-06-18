import SwiftUI

struct PersonRelationListView: View {
  let personId: Int

  @State private var reloader = false

  func load(limit: Int, offset: Int) async -> PagedDTO<PersonRelationListItemDTO>? {
    do {
      let resp = try await PersonService.getPersonRelations(
        personId, limit: limit, offset: offset)
      guard let db = await AppContext.shared.databaseIfAvailable() else {
        return PagedDTO(
          data: resp.data.map { PersonRelationListItemDTO(relation: $0, isCollected: false) },
          total: resp.total
        )
      }
      let statuses = try await db.personCollectionStatuses(
        personIds: resp.data.map { $0.person.id }
      )
      return PagedDTO(
        data: resp.data.map {
          PersonRelationListItemDTO(
            relation: $0,
            isCollected: statuses[$0.person.id] ?? false
          )
        },
        total: resp.total
      )
    } catch {
      Notifier.shared.alert(error: error)
    }
    return nil
  }

  var body: some View {
    ScrollView {
      OffsetPagedView<PersonRelationListItemDTO, _>(reloader: reloader, nextPageFunc: load) {
        item in
        PersonRelationItemView(item: item.relation, isCollected: item.isCollected)
      }
      .padding(8)
    }
    .navigationTitle("关联人物")
    .navigationBarTitleDisplayMode(.inline)
  }
}
