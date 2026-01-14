import SwiftData
import SwiftUI

struct SearchPersonPickerView: View {
  @Environment(\.dismiss) var dismiss

  let onSelect: (Int) -> Void

  @State private var searchText: String = ""
  @State private var searching: Bool = false
  @State private var remote: Bool = false

  var body: some View {
    NavigationStack {
      ScrollView {
        VStack {
          if searchText.isEmpty {
            Text("输入关键字搜索")
              .foregroundStyle(.secondary)
              .padding(8)
          } else {
            if remote {
              SearchPersonPickerRemoteView(text: searchText, onSelect: onSelect)
            } else {
              SearchPersonPickerLocalView(text: searchText, onSelect: onSelect)
            }
          }
        }.padding()
      }
      .animation(.default, value: searchText)
      .animation(.default, value: remote)
      .navigationTitle("搜索人物")
      .navigationBarTitleDisplayMode(.inline)
      .searchable(text: $searchText, isPresented: $searching, prompt: "搜索人物")
      .searchPresentationToolbarBehavior(.avoidHidingContent)
      .onSubmit(of: .search) {
        remote = true
      }
      .onChange(of: searchText) { _, _ in
        remote = false
      }
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button {
            dismiss()
          } label: {
            Label("取消", systemImage: "xmark")
          }
        }
        ToolbarItem(placement: .confirmationAction) {
          Image(systemName: remote ? "globe" : "internaldrive")
            .foregroundColor(remote ? .blue : .green)
        }
      }
    }
  }
}

struct SearchPersonPickerRemoteView: View {
  let text: String
  let onSelect: (Int) -> Void

  @Environment(\.dismiss) var dismiss

  private func fetch(limit: Int, offset: Int) async -> PagedDTO<SlimPersonDTO>? {
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
      SearchPersonPickerItemView(personId: item.id) { selectedId in
        onSelect(selectedId)
        dismiss()
      }
    }
  }
}

struct SearchPersonPickerLocalView: View {
  let text: String
  let onSelect: (Int) -> Void

  @Environment(\.dismiss) var dismiss
  @Query private var persons: [Person]

  init(text: String, onSelect: @escaping (Int) -> Void) {
    self.text = text.gb
    self.onSelect = onSelect

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
        .onTapGesture {
          onSelect(person.personId)
          dismiss()
        }
      }
    }
  }
}

struct SearchPersonPickerItemView: View {
  let personId: Int
  let onSelect: (Int) -> Void

  @Query private var persons: [Person]
  private var person: Person? { persons.first }

  init(personId: Int, onSelect: @escaping (Int) -> Void) {
    self.personId = personId
    self.onSelect = onSelect

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
    .onTapGesture {
      onSelect(personId)
    }
  }
}
