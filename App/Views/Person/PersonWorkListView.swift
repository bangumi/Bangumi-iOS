import Flow
import SwiftUI

struct PersonWorkListView: View {
  let personId: Int

  @State private var subjectType: SubjectType = .none
  @State private var reloader = false

  func load(limit: Int, offset: Int) async -> PagedDTO<PersonWorkDTO>? {
    do {
      let resp = try await PersonService.getPersonWorks(
        personId, subjectType: subjectType, limit: limit, offset: offset)
      return resp
    } catch {
      Notifier.shared.alert(error: error)
    }
    return nil
  }

  var body: some View {
    Picker("Subject Type", selection: $subjectType.animated()) {
      ForEach(SubjectType.allCases) { type in
        Text(type.description).tag(type)
      }
    }
    .padding(.horizontal, 8)
    .pickerStyle(.segmented)
    .onChange(of: subjectType) { _, _ in
      withAnimation(.default) {
        reloader.toggle()
      }
    }
    ScrollView {
      OffsetPagedView<PersonWorkDTO, _>(limit: 10, reloader: reloader, nextPageFunc: load) { item in
        PersonWorksItemView(item: item)
      }
      .padding(8)
    }
    .buttonStyle(.navigation)
    .navigationTitle("参与作品")
    .navigationBarTitleDisplayMode(.inline)
  }
}
