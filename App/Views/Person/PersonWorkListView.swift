import Flow
import SwiftData
import SwiftUI

struct PersonWorkListView: View {
  let personId: Int

  @State private var subjectType: SubjectType = .none
  @State private var reloader = false

  func load(limit: Int, offset: Int) async -> PagedDTO<PersonWorkDTO>? {
    do {
      let resp = try await Chii.shared.getPersonWorks(
        personId, subjectType: subjectType, limit: limit, offset: offset)
      return resp
    } catch {
      Notifier.shared.alert(error: error)
    }
    return nil
  }

  var body: some View {
    Picker("Subject Type", selection: $subjectType) {
      ForEach(SubjectType.allCases) { type in
        Text(type.description).tag(type)
      }
    }
    .padding(.horizontal, 8)
    .pickerStyle(.segmented)
    .onChange(of: subjectType) { _, _ in
      reloader.toggle()
    }
    ScrollView {
      PageView<PersonWorkDTO, _>(limit: 10, reloader: reloader, nextPageFunc: load) { item in
        PersonWorksItemView(item: item)
      }
      .padding(8)
    }
    .buttonStyle(.navigation)
    .navigationTitle("参与作品")
    .navigationBarTitleDisplayMode(.inline)
  }
}

#Preview {
  let person = Person.preview
  return PersonWorkListView(personId: person.personId)
}
