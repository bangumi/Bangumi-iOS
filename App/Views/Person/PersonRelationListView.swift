import OSLog
import SwiftUI

struct PersonRelationListView: View {
  let personId: Int

  @State private var reloader = false
  @State private var collectionStatuses: [Int: Bool] = [:]
  @State private var loadedPersonIds: Set<Int> = []

  private func loadCollectionStatuses(personIds: [Int]) async {
    guard !personIds.isEmpty else { return }
    do {
      guard let db = await AppContext.shared.databaseIfAvailable() else { return }
      let statuses = try await db.personCollectionStatuses(personIds: personIds)
      collectionStatuses.merge(statuses) { _, new in new }
    } catch {
      Logger.app.error("Failed to load person collection statuses: \(error)")
    }
  }

  private func handleMonoCollectionInvalidation(_ notification: Notification) {
    guard let personId = MonoCollectionInvalidation.personId(from: notification),
      loadedPersonIds.contains(personId)
    else {
      return
    }
    Task {
      await loadCollectionStatuses(personIds: [personId])
    }
  }

  func load(limit: Int, offset: Int) async -> PagedDTO<PersonRelationDTO>? {
    do {
      let resp = try await PersonService.getPersonRelations(
        personId, limit: limit, offset: offset)
      let personIds = resp.data.map { $0.person.id }
      loadedPersonIds.formUnion(personIds)
      await loadCollectionStatuses(personIds: personIds)
      return resp
    } catch {
      Notifier.shared.alert(error: error)
    }
    return nil
  }

  var body: some View {
    ScrollView {
      OffsetPagedView<PersonRelationDTO, _>(reloader: reloader, nextPageFunc: load) { item in
        PersonRelationItemView(
          item: item,
          isCollected: collectionStatuses[item.person.id] ?? false
        )
      }
      .padding(8)
    }
    .onReceive(
      NotificationCenter.default.publisher(for: MonoCollectionInvalidation.notificationName),
      perform: handleMonoCollectionInvalidation
    )
    .onAppear {
      Task {
        await loadCollectionStatuses(personIds: Array(loadedPersonIds))
      }
    }
    .navigationTitle("关联人物")
    .navigationBarTitleDisplayMode(.inline)
  }
}
