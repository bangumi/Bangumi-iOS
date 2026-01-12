import OSLog
import SwiftData
import SwiftUI

struct SearchPersonView: View {
  let text: String

  func fetch(limit: Int, offset: Int) async -> PagedDTO<SlimPersonDTO>? {
    do {
      guard let db = await Chii.shared.db else {
        throw ChiiError.uninitialized
      }
      let resp = try await Chii.shared.searchPersons(
        keyword: text.gb, limit: limit, offset: offset)
      for item in resp.data {
        try await db.savePerson(item)
      }
      await db.commit()
      return resp
    } catch {
      Notifier.shared.alert(error: error)
    }
    return nil
  }

  var body: some View {
    PageView<SlimPersonDTO, _>(nextPageFunc: fetch) { item in
      SearchPersonItemView(personId: item.id)
    }
  }
}

struct SearchPersonItemView: View {
  let personId: Int

  @Query private var persons: [Person]
  private var person: Person? { persons.first }

  init(personId: Int) {
    self.personId = personId

    let desc = FetchDescriptor<Person>(
      predicate: #Predicate<Person> {
        return $0.personId == personId
      }
    )
    _persons = Query(desc)
  }

  var body: some View {
    CardView {
      if let person = person {
        PersonLargeRowView(person: person)
      }
    }
  }
}

struct SearchPersonLocalView: View {
  let text: String

  @Query private var persons: [Person]

  init(text: String) {
    self.text = text.gb

    var desc = FetchDescriptor<Person>(
      predicate: #Predicate<Person> {
        return $0.name.localizedStandardContains(text)
          || $0.alias.localizedStandardContains(text)
      })
    desc.fetchLimit = 20
    _persons = Query(desc)
  }

  var body: some View {
    LazyVStack {
      ForEach(persons) { person in
        CardView {
          PersonLargeRowView(person: person)
        }
      }
    }
  }
}
