import SwiftData
import SwiftUI

struct SearchSubjectPickerView: View {
  @Environment(\.dismiss) var dismiss

  let onSelect: (Int) -> Void

  @State private var searchText: String = ""
  @State private var searching: Bool = false
  @State private var remote: Bool = false
  @State private var subjectType: SubjectType = .none

  var body: some View {
    NavigationStack {
      ScrollView {
        VStack(spacing: 8) {
          Picker("Subject Type", selection: $subjectType) {
            Text("全部").tag(SubjectType.none)
            ForEach(SubjectType.allTypes) { type in
              Text(type.description).tag(type)
            }
          }.pickerStyle(.segmented)

          if searchText.isEmpty {
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
      .animation(.default, value: subjectType)
      .animation(.default, value: searchText)
      .animation(.default, value: remote)
      .navigationTitle("搜索条目")
      .navigationBarTitleDisplayMode(.inline)
      .searchable(text: $searchText, isPresented: $searching, prompt: "搜索条目")
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

struct SearchSubjectPickerRemoteView: View {
  let text: String
  let subjectType: SubjectType
  let onSelect: (Int) -> Void

  @Environment(\.dismiss) var dismiss
  @State private var reloader = false

  private func fetch(limit: Int, offset: Int) async -> PagedDTO<SlimSubjectDTO>? {
    do {
      guard let db = await Chii.shared.db else {
        throw ChiiError.uninitialized
      }
      let resp = try await Chii.shared.searchSubjects(
        keyword: text.gb, type: subjectType, limit: limit, offset: offset)
      for item in resp.data {
        try await db.saveSubject(item)
      }
      await db.commit()
      return resp
    } catch {
      Notifier.shared.alert(error: error)
    }
    return nil
  }

  var body: some View {
    PageView<SlimSubjectDTO, _>(reloader: reloader, nextPageFunc: fetch) { item in
      SearchSubjectPickerItemView(subjectId: item.id) { selectedId in
        onSelect(selectedId)
        dismiss()
      }
    }
    .onChange(of: subjectType) { _, _ in
      reloader.toggle()
    }
  }
}

struct SearchSubjectPickerLocalView: View {
  let text: String
  let subjectType: SubjectType
  let onSelect: (Int) -> Void

  @Environment(\.dismiss) var dismiss
  @Query private var subjects: [Subject]

  init(text: String, subjectType: SubjectType, onSelect: @escaping (Int) -> Void) {
    self.text = text.gb
    self.subjectType = subjectType
    self.onSelect = onSelect

    let stype = subjectType.rawValue
    var desc = FetchDescriptor<Subject>(
      predicate: #Predicate<Subject> {
        return (stype == 0 || stype == $0.type)
          && ($0.name.localizedStandardContains(text)
            || $0.alias.localizedStandardContains(text))
      })
    desc.fetchLimit = 20
    _subjects = Query(desc)
  }

  var body: some View {
    LazyVStack {
      ForEach(subjects) { subject in
        CardView {
          SubjectLargeRowView(subject: subject)
        }
        .onTapGesture {
          onSelect(subject.subjectId)
          dismiss()
        }
      }
    }
  }
}

struct SearchSubjectPickerItemView: View {
  let subjectId: Int
  let onSelect: (Int) -> Void

  @Query private var subjects: [Subject]
  private var subject: Subject? { subjects.first }

  init(subjectId: Int, onSelect: @escaping (Int) -> Void) {
    self.subjectId = subjectId
    self.onSelect = onSelect

    let desc = FetchDescriptor<Subject>(
      predicate: #Predicate<Subject> {
        return $0.subjectId == subjectId
      }
    )
    _subjects = Query(desc)
  }

  var body: some View {
    CardView {
      if let subject = subject {
        SubjectLargeRowView(subject: subject)
      }
    }
    .onTapGesture {
      onSelect(subjectId)
    }
  }
}
