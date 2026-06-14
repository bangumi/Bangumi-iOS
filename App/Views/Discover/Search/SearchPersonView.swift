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
      try await db.commit()
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

  var body: some View {
    CardView {
      if let person = person {
        PersonLargeRowView(person: person)
      }
    }
    .task(id: personId) {
      await load()
    }
  }
}

struct SearchPersonLocalView: View {
  let text: String

  @State private var persons: [PersonDTO] = []

  private func load() async {
    do {
      let db = try await AppContext.shared.getDB()
      persons = try await db.fetchLocalPersons(search: text.gb)
    } catch {
      Notifier.shared.alert(error: error)
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
  }
}
