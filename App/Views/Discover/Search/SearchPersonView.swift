import OSLog
import SwiftUI

struct SearchPersonView: View {
  let text: String

  func fetch(limit: Int, offset: Int) async -> PagedDTO<SlimPersonDTO>? {
    do {
      guard let db = await AppContext.shared.databaseIfAvailable() else {
        throw ChiiError.uninitialized
      }
      let resp = try await SearchService.searchPersons(
        keyword: text.gb, limit: limit, offset: offset)
      for item in resp.data {
        try await db.savePerson(item)
      }
      return resp
    } catch {
      Notifier.shared.alert(error: error)
    }
    return nil
  }

  var body: some View {
    OffsetPagedView<SlimPersonDTO, _>(nextPageFunc: fetch) { item in
      SearchPersonItemView(personId: item.id)
    }
    .emptyPlaceholder {
      ThemedEmptyState(
        systemImage: "magnifyingglass",
        title: "没有找到相关结果",
        description: "换个关键字再试试")
    }
  }
}

struct SearchPersonItemView: View {
  let personId: Int

  @State private var person: PersonDTO?

  private func load() async {
    do {
      let db = try await AppContext.shared.getDB()
      person = try await db.getPersonDTO(personId)
    } catch {
      Notifier.shared.alert(error: error)
    }
  }

  private func handleMonoCollectionInvalidation(_ notification: Notification) {
    guard MonoCollectionInvalidation.personId(from: notification) == personId else {
      return
    }
    Task {
      await load()
    }
  }

  var body: some View {
    CardView {
      if let person = person {
        PersonLargeRowView(person: person)
      }
    }
    .task(id: personId) {
      await load()
    }
    .onReceive(
      NotificationCenter.default.publisher(for: MonoCollectionInvalidation.notificationName),
      perform: handleMonoCollectionInvalidation
    )
    .onAppear {
      Task {
        await load()
      }
    }
  }
}

struct SearchPersonLocalView: View {
  let text: String
  let onGoRemote: () -> Void

  @State private var persons: [PersonDTO] = []
  @State private var loaded: Bool = false

  private func load() async {
    do {
      let db = try await AppContext.shared.getDB()
      let fetched = try await db.fetchLocalPersons(search: text.gb)
      withAnimation(.default) {
        persons = fetched
        loaded = true
      }
    } catch {
      Notifier.shared.alert(error: error)
    }
  }

  private func handleMonoCollectionInvalidation(_ notification: Notification) {
    guard let personId = MonoCollectionInvalidation.personId(from: notification),
      persons.contains(where: { $0.id == personId })
    else {
      return
    }
    Task {
      await load()
    }
  }

  var body: some View {
    LazyVStack {
      ForEach(persons) { person in
        CardView {
          PersonLargeRowView(person: person)
        }
      }
    }
    .task(id: text) {
      await load()
    }
    .onReceive(
      NotificationCenter.default.publisher(for: MonoCollectionInvalidation.notificationName),
      perform: handleMonoCollectionInvalidation
    )
    .onAppear {
      Task {
        await load()
      }
    }

    if loaded, persons.isEmpty {
      ThemedEmptyState(
        systemImage: "internaldrive",
        title: "本地缓存没有匹配结果",
        description: "在线搜索可以查找全站数据",
        primary: .init(title: "在线搜索", systemImage: "globe", handler: onGoRemote))
    }
  }
}
