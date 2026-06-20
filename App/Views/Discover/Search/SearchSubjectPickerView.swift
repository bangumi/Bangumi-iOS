import SwiftUI

struct SearchSubjectPickerView: View {
  @Environment(\.dismiss) var dismiss

  let onSelect: (Int) -> Void

  @State private var searchText: String = ""
  @State private var searching: Bool = false
  @State private var remote: Bool = false
  @State private var subjectType: SubjectType = .none
  @State private var showsResults = false

  var body: some View {
    NavigationStack {
      ScrollView {
        VStack(spacing: 8) {
          Picker("Subject Type", selection: $subjectType.animated()) {
            Text("全部").tag(SubjectType.none)
            ForEach(SubjectType.allTypes) { type in
              Text(type.description).tag(type)
            }
          }.pickerStyle(.segmented)

          if !showsResults {
            Text("输入关键字搜索")
              .foregroundStyle(.secondary)
              .padding(8)
          } else {
            if remote {
              SearchSubjectPickerRemoteView(
                text: searchText,
                subjectType: subjectType,
                onSelect: onSelect
              )
            } else {
              SearchSubjectPickerLocalView(
                text: searchText,
                subjectType: subjectType,
                onSelect: onSelect
              )
            }
          }
        }.padding()
      }
      .navigationTitle("搜索条目")
      .navigationBarTitleDisplayMode(.inline)
      .searchable(text: $searchText, isPresented: $searching, prompt: "搜索条目")
      .searchInputTraits()
      .searchPresentationToolbarBehavior(.avoidHidingContent)
      .onAppear {
        showsResults = !searchText.isEmpty
      }
      .onSubmit(of: .search) {
        withAnimation(.default) {
          remote = true
        }
      }
      .onChange(of: searchText) { _, newValue in
        let nextShowsResults = !newValue.isEmpty
        if showsResults != nextShowsResults {
          withAnimation(.default) {
            showsResults = nextShowsResults
          }
        }
        if remote {
          withAnimation(.default) {
            remote = false
          }
        }
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

struct SearchSubjectPickerRemoteView: View {
  let text: String
  let subjectType: SubjectType
  let onSelect: (Int) -> Void

  @Environment(\.dismiss) var dismiss
  @State private var reloader = false

  private func fetch(limit: Int, offset: Int) async -> PagedDTO<SubjectListItemDTO>? {
    do {
      guard let db = await AppContext.shared.databaseIfAvailable() else {
        throw ChiiError.uninitialized
      }
      let resp = try await SearchService.searchSubjects(
        keyword: text.gb, type: subjectType, limit: limit, offset: offset)
      for item in resp.data {
        try await db.saveSubject(item)
      }
      return PagedDTO(data: try await db.makeSubjectListItems(resp.data), total: resp.total)
    } catch {
      Notifier.shared.alert(error: error)
    }
    return nil
  }

  var body: some View {
    OffsetPagedView<SubjectListItemDTO, _>(reloader: reloader, nextPageFunc: fetch) { item in
      SearchSubjectPickerItemView(
        subject: item.subject,
        collectionType: item.collectionType
      ) { selectedId in
        onSelect(selectedId)
        dismiss()
      }
    }
    .onChange(of: subjectType) { _, _ in
      withAnimation(.default) {
        reloader.toggle()
      }
    }
  }
}

struct SearchSubjectPickerLocalView: View {
  let text: String
  let subjectType: SubjectType
  let onSelect: (Int) -> Void

  @Environment(\.dismiss) var dismiss
  @State private var subjects: [SubjectDTO] = []

  private func load() async {
    do {
      let db = try await AppContext.shared.getDB()
      let fetched = try await db.fetchLocalSubjects(search: text.gb, subjectType: subjectType)
      withAnimation(.default) {
        subjects = fetched
      }
    } catch {
      Notifier.shared.alert(error: error)
    }
  }

  var body: some View {
    LazyVStack {
      ForEach(subjects) { subject in
        CardView {
          SubjectLargeRowView(subject: subject)
        }
        .onTapGesture {
          onSelect(subject.id)
          dismiss()
        }
      }
    }
    .task(id: "\(text)-\(subjectType.rawValue)") {
      await load()
    }
  }
}

struct SearchSubjectPickerItemView: View {
  let subject: SlimSubjectDTO
  let collectionType: CollectionType
  let onSelect: (Int) -> Void

  init(
    subject: SlimSubjectDTO,
    collectionType: CollectionType,
    onSelect: @escaping (Int) -> Void
  ) {
    self.subject = subject
    self.collectionType = collectionType
    self.onSelect = onSelect
  }

  var body: some View {
    CardView {
      SubjectSlimRowView(subject: subject, collectionType: collectionType)
    }
    .onTapGesture {
      onSelect(subject.id)
    }
  }
}
