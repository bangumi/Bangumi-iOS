import SwiftUI

struct ExportView: View {
  @State private var selectedFields: Set<ExportableField> = ExportableField.defaultFields
  @State private var subjectType: SubjectType? = nil
  @State private var collectionType: CollectionType? = nil
  @State private var coverSize: CoverExportSize = .r400
  @State private var isExporting: Bool = false
  @State private var exportURL: URL? = nil
  @State private var showShareSheet: Bool = false
  @State private var subjectCount: Int = 0

  private var showCoverSizePicker: Bool {
    selectedFields.contains(.cover)
  }

  var body: some View {
    Form {
      Section(header: Text("筛选条件")) {
        Picker("条目类型", selection: $subjectType) {
          Text("全部").tag(nil as SubjectType?)
          ForEach(SubjectType.allTypes) { type in
            Text(type.description).tag(type as SubjectType?)
          }
        }

        Picker("收藏状态", selection: $collectionType) {
          Text("全部").tag(nil as CollectionType?)
          ForEach(CollectionType.allTypes()) { type in
            Text(type.description(subjectType)).tag(type as CollectionType?)
          }
        }

        HStack {
          Text("符合条件的条目")
          Spacer()
          Text("\(subjectCount) 个")
            .foregroundStyle(.secondary)
        }
      }

      Section(header: Text("导出字段（\(selectedFields.count)/\(ExportableField.allCases.count)）")) {
        ForEach(ExportableField.allCases) { field in
          Toggle(
            field.label,
            isOn: Binding(
              get: { selectedFields.contains(field) },
              set: { isSelected in
                withAnimation {
                  if isSelected {
                    selectedFields.insert(field)
                  } else {
                    selectedFields.remove(field)
                  }
                }
              }
            ))
        }
      }

      if showCoverSizePicker {
        Section(header: Text("封面设置")) {
          Picker("封面尺寸", selection: $coverSize) {
            ForEach(CoverExportSize.allCases) { size in
              Text(size.label).tag(size)
            }
          }
        }
      }

      Section {
        Button {
          exportToCSV()
        } label: {
          HStack {
            Spacer()
            if isExporting {
              ProgressView()
                .padding(.trailing, 8)
              Text("导出中...")
            } else {
              Image(systemName: "square.and.arrow.up")
                .padding(.trailing, 4)
              Text("导出 CSV")
            }
            Spacer()
          }
        }
        .disabled(selectedFields.isEmpty || subjectCount == 0 || isExporting)
      }
    }
    .disabled(isExporting)
    .navigationTitle("导出收藏")
    .navigationBarTitleDisplayMode(.inline)
    .toolbar {
      ToolbarItem(placement: .topBarTrailing) {
        Button("全选") {
          selectedFields = Set(ExportableField.allCases)
        }
        .disabled(isExporting)
      }
    }
    .sheet(isPresented: $showShareSheet) {
      if let url = exportURL {
        ShareSheet(items: [url])
      }
    }
    .task {
      refreshCount()
    }
    .onChange(of: subjectType) {
      refreshCount()
    }
    .onChange(of: collectionType) {
      refreshCount()
    }
  }

  private func refreshCount() {
    Task {
      do {
        let db = try await Chii.shared.getDB()
        let count = try await db.countSubjects(
          subjectType: subjectType,
          collectionType: collectionType
        )
        await MainActor.run {
          subjectCount = count
        }
      } catch {
        await MainActor.run {
          subjectCount = 0
        }
      }
    }
  }

  private func exportToCSV() {
    isExporting = true

    Task {
      do {
        let db = try await Chii.shared.getDB()
        if let url = try await db.exportSubjectsToCSV(
          subjectType: subjectType,
          collectionType: collectionType,
          fields: selectedFields,
          coverSize: coverSize
        ) {
          await MainActor.run {
            exportURL = url
            showShareSheet = true
            isExporting = false
          }
        } else {
          await MainActor.run {
            isExporting = false
            Notifier.shared.alert(message: "导出失败")
          }
        }
      } catch {
        await MainActor.run {
          isExporting = false
          Notifier.shared.alert(message: "导出失败")
        }
      }
    }
  }
}

struct ShareSheet: UIViewControllerRepresentable {
  let items: [Any]

  func makeUIViewController(context: Context) -> UIActivityViewController {
    UIActivityViewController(activityItems: items, applicationActivities: nil)
  }

  func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

#Preview {
  let container = mockContainer()

  return NavigationStack {
    ExportView()
  }
  .modelContainer(container)
}
