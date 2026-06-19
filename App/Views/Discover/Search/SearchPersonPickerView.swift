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
      .searchInputTraits()
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
  @State private var persons: [PersonDTO] = []

  private func load() async {
    do {
      let db = try await AppContext.shared.getDB()
      persons = try await db.fetchLocalPersons(search: text.gb)
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
        .onTapGesture {
          onSelect(person.id)
          dismiss()
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
  }
}

struct SearchPersonPickerItemView: View {
  let personId: Int
  let onSelect: (Int) -> Void

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
    .onTapGesture {
      onSelect(personId)
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
