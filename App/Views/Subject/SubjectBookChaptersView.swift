import Foundation
import SwiftUI

enum BookChapterMode {
  case large
  case row
  case tile
}

private enum BookProgressSummaryLayout {
  case row
  case tile
}

private enum BookProgressQuickUpdate: Equatable {
  case chapters
  case volumes
}

struct ChapterData {
  let epStatus: Int
  let volStatus: Int
  let epsDesc: String
  let volumesDesc: String
}

struct ChapterState {
  let updating: Bool
  let updateButtonDisable: Bool
}

struct ChapterInputs {
  let eps: Binding<String>
  let vols: Binding<String>
}

struct ChapterActions {
  let incrEps: () -> Void
  let incrVols: () -> Void
  let update: () -> Void
}

struct SubjectBookChaptersView: View {
  let subject: SubjectDTO
  let mode: BookChapterMode
  var reload: (() async -> Void)? = nil

  var body: some View {
    switch mode {
    case .large:
      LargeBookProgressEditorView(subject: subject, reload: reload)

    case .row:
      BookProgressSummaryView(subject: subject, layout: .row, reload: reload)

    case .tile:
      BookProgressSummaryView(subject: subject, layout: .tile, reload: reload)
    }
  }
}

private struct LargeBookProgressEditorView: View {
  let subject: SubjectDTO
  let reload: (() async -> Void)?

  @State private var inputEps: String = ""
  @State private var eps: Int? = nil
  @State private var inputVols: String = ""
  @State private var vols: Int? = nil
  @State private var updating: Bool = false

  var updateButtonDisable: Bool {
    if updating {
      return true
    }
    return eps == nil && vols == nil
  }

  var epStatus: Int {
    return subject.interest?.epStatus ?? 0
  }

  var volStatus: Int {
    return subject.interest?.volStatus ?? 0
  }

  func parseInputEps() {
    if let newEps = Int(inputEps) {
      self.eps = newEps
    } else {
      self.eps = nil
    }
  }

  func parseInputVols() {
    if let newVols = Int(inputVols) {
      self.vols = newVols
    } else {
      self.vols = nil
    }
  }

  func incrEps() {
    if let value = eps {
      self.inputEps = "\(value+1)"
    } else {
      self.inputEps = "\(epStatus+1)"
    }
    parseInputEps()
  }

  func incrVols() {
    if let value = vols {
      self.inputVols = "\(value+1)"
    } else {
      self.inputVols = "\(volStatus+1)"
    }
    parseInputVols()
  }

  func reset() {
    self.eps = nil
    self.vols = nil
    self.inputEps = ""
    self.inputVols = ""
  }

  func update() {
    self.updating = true

    Task {
      do {
        try await SubjectRepository.updateSubjectProgress(
          subjectId: subject.id, eps: eps, vols: vols)
        await reload?()
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
      } catch {
        Notifier.shared.alert(error: error)
      }
      self.reset()
      self.updating = false
    }
  }

  var chapterData: ChapterData {
    ChapterData(
      epStatus: epStatus,
      volStatus: volStatus,
      epsDesc: subject.epsDesc,
      volumesDesc: subject.volumesDesc
    )
  }

  var chapterState: ChapterState {
    ChapterState(
      updating: updating,
      updateButtonDisable: updateButtonDisable
    )
  }

  var chapterInputs: ChapterInputs {
    ChapterInputs(
      eps: $inputEps,
      vols: $inputVols
    )
  }

  var chapterActions: ChapterActions {
    ChapterActions(
      incrEps: incrEps,
      incrVols: incrVols,
      update: update
    )
  }

  var body: some View {
    LargeChapterView(
      data: chapterData,
      state: chapterState,
      inputs: chapterInputs,
      actions: chapterActions
    )
    .disabled(updating)
    .onChange(of: inputEps) { _, _ in parseInputEps() }
    .onChange(of: inputVols) { _, _ in parseInputVols() }
  }
}

struct LargeChapterView: View {
  let data: ChapterData
  let state: ChapterState
  let inputs: ChapterInputs
  let actions: ChapterActions

  var body: some View {
    CardView {
      HStack {
        VStack {
          HStack(alignment: .firstTextBaseline, spacing: 0) {
            Text("Chap.").foregroundStyle(.secondary)
            TextField("\(data.epStatus)", text: inputs.eps)
              .keyboardType(.numberPad)
              .frame(minWidth: 50, maxWidth: 75)
              .multilineTextAlignment(.trailing)
              .padding(.trailing, 2)
              .textFieldStyle(.roundedBorder)
            Text("/").foregroundStyle(.secondary)
            Text(data.epsDesc).foregroundStyle(.secondary)
              .padding(.trailing, 5)
            Button {
              actions.incrEps()
            } label: {
              Image(systemName: "plus.circle")
                .foregroundStyle(.secondary)
            }.buttonStyle(.scale)
            Spacer()
          }.monospaced()
          HStack(alignment: .firstTextBaseline, spacing: 0) {
            Text("Vol. ").foregroundStyle(.secondary)
            TextField("\(data.volStatus)", text: inputs.vols)
              .keyboardType(.numberPad)
              .frame(minWidth: 50, maxWidth: 75)
              .multilineTextAlignment(.trailing)
              .padding(.trailing, 2)
              .textFieldStyle(.roundedBorder)
            Text("/").foregroundStyle(.secondary)
            Text(data.volumesDesc).foregroundStyle(.secondary)
              .padding(.trailing, 5)
            Button {
              actions.incrVols()
            } label: {
              Image(systemName: "plus.circle")
                .foregroundStyle(.secondary)
            }.buttonStyle(.scale)
            Spacer()
          }.monospaced()
        }
        Spacer()
        if state.updating {
          ZStack {
            Button("更新", action: {})
              .disabled(true)
              .hidden()
              .adaptiveButtonStyle(.borderedProminent)
            ProgressView()
          }
        } else {
          Button("更新", action: actions.update)
            .disabled(state.updateButtonDisable)
            .adaptiveButtonStyle(.borderedProminent)
        }
      }
    }
  }
}

private struct BookProgressSummaryView: View {
  let subject: SubjectDTO
  let layout: BookProgressSummaryLayout
  let reload: (() async -> Void)?

  @State private var showingEditor = false
  @State private var quickUpdate: BookProgressQuickUpdate?

  private var epStatus: Int {
    subject.interest?.epStatus ?? 0
  }

  private var volStatus: Int {
    subject.interest?.volStatus ?? 0
  }

  private func increment(_ target: BookProgressQuickUpdate) {
    guard quickUpdate == nil else {
      return
    }

    quickUpdate = target
    Task {
      defer {
        quickUpdate = nil
      }
      do {
        switch target {
        case .chapters:
          try await SubjectRepository.updateSubjectProgress(
            subjectId: subject.id,
            eps: epStatus + 1,
            vols: nil
          )
        case .volumes:
          try await SubjectRepository.updateSubjectProgress(
            subjectId: subject.id,
            eps: nil,
            vols: volStatus + 1
          )
        }
        await reload?()
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
      } catch {
        Notifier.shared.alert(error: error)
      }
    }
  }

  var body: some View {
    Group {
      switch layout {
      case .row:
        HStack(alignment: .firstTextBaseline, spacing: 4) {
          Text(verbatim: "Chap.")
            .font(.footnote)
            .foregroundStyle(.secondary)
          BookProgressMetric(value: epStatus, total: subject.epsDesc)
          BookProgressQuickUpdateButton(
            accessibilityLabel: "话数加一",
            updating: quickUpdate == .chapters,
            disabled: quickUpdate != nil
          ) {
            increment(.chapters)
          }

          Text("·")
            .font(.footnote)
            .foregroundStyle(.secondary)

          Text(verbatim: "Vol.")
            .font(.footnote)
            .foregroundStyle(.secondary)
          BookProgressMetric(value: volStatus, total: subject.volumesDesc)
          BookProgressQuickUpdateButton(
            accessibilityLabel: "卷数加一",
            updating: quickUpdate == .volumes,
            disabled: quickUpdate != nil
          ) {
            increment(.volumes)
          }

          Spacer(minLength: 0)

          BookProgressEditButton(
            disabled: quickUpdate != nil
          ) {
            showingEditor = true
          }
        }
        .lineLimit(1)
      case .tile:
        BookProgressTileControls(
          chapterValue: epStatus,
          chapterTotal: subject.epsDesc,
          volumeValue: volStatus,
          volumeTotal: subject.volumesDesc,
          quickUpdate: quickUpdate,
          incrementChapters: {
            increment(.chapters)
          },
          incrementVolumes: {
            increment(.volumes)
          },
          edit: {
            showingEditor = true
          }
        )
      }
    }
    .sheet(isPresented: $showingEditor) {
      BookProgressEditorSheet(subject: subject, reload: reload)
        .presentationDragIndicator(.visible)
    }
  }
}

private struct BookProgressMetric: View {
  let value: Int
  let total: String

  var body: some View {
    HStack(alignment: .firstTextBaseline, spacing: 0) {
      Text(value, format: .number)
        .font(.subheadline)
        .fontWeight(.medium)
        .foregroundStyle(.linkText)
        .monospacedDigit()

      Text(verbatim: "/\(total)")
        .font(.footnote)
        .foregroundStyle(.secondary)
        .monospacedDigit()
    }
  }
}

private struct BookProgressQuickUpdateButton: View {
  let accessibilityLabel: LocalizedStringKey
  let updating: Bool
  let disabled: Bool
  let action: () -> Void

  var body: some View {
    Button(action: action) {
      Image(systemName: updating ? "ellipsis.circle" : "plus.circle")
        .contentTransition(.symbolEffect(.replace))
        .animation(.default, value: updating)
        .progressActionLabelStyle(.inline)
    }
    .progressActionButtonStyle()
    .disabled(disabled)
    .accessibilityLabel(accessibilityLabel)
    .accessibilityValue(updating ? "正在更新" : "")
  }
}

private struct BookProgressEditButton: View {
  let disabled: Bool
  let action: () -> Void

  var body: some View {
    Button(action: action) {
      Label {
        Text("更新")
      } icon: {
        Image(systemName: "pencil")
          .imageScale(.small)
      }
      .progressActionLabelStyle(.inline)
    }
    .progressActionButtonStyle()
    .disabled(disabled)
    .accessibilityLabel("编辑阅读进度")
  }
}

private struct BookProgressTileEditButton: View {
  let disabled: Bool
  let action: () -> Void

  var body: some View {
    Button(action: action) {
      Image(systemName: "plusminus.circle")
        .imageScale(.large)
        .progressActionLabelStyle(.inline)
    }
    .progressActionButtonStyle()
    .disabled(disabled)
    .accessibilityLabel("编辑阅读进度")
  }
}

private struct BookProgressTileControls: View {
  let chapterValue: Int
  let chapterTotal: String
  let volumeValue: Int
  let volumeTotal: String
  let quickUpdate: BookProgressQuickUpdate?
  let incrementChapters: () -> Void
  let incrementVolumes: () -> Void
  let edit: () -> Void

  var body: some View {
    HStack(spacing: 0) {
      Grid(alignment: .leading, horizontalSpacing: 4, verticalSpacing: 2) {
        GridRow(alignment: .firstTextBaseline) {
          Text(verbatim: "Chap.")
            .font(.footnote)
            .foregroundStyle(.secondary)
            .gridColumnAlignment(.leading)

          BookProgressTileMetricControl(
            value: chapterValue,
            total: chapterTotal,
            accessibilityLabel: "话数加一",
            updating: quickUpdate == .chapters,
            disabled: quickUpdate != nil,
            action: incrementChapters
          )
          .gridColumnAlignment(.trailing)
        }

        GridRow(alignment: .firstTextBaseline) {
          Text(verbatim: "Vol.")
            .font(.footnote)
            .foregroundStyle(.secondary)

          BookProgressTileMetricControl(
            value: volumeValue,
            total: volumeTotal,
            accessibilityLabel: "卷数加一",
            updating: quickUpdate == .volumes,
            disabled: quickUpdate != nil,
            action: incrementVolumes
          )
        }
      }
      .lineLimit(1)

      Spacer(minLength: 4)

      BookProgressTileEditButton(
        disabled: quickUpdate != nil,
        action: edit
      )
    }
    .frame(maxWidth: .infinity, alignment: .leading)
  }
}

private struct BookProgressTileMetricControl: View {
  let value: Int
  let total: String
  let accessibilityLabel: LocalizedStringKey
  let updating: Bool
  let disabled: Bool
  let action: () -> Void

  var body: some View {
    HStack(alignment: .firstTextBaseline, spacing: 4) {
      BookProgressMetric(value: value, total: total)

      BookProgressQuickUpdateButton(
        accessibilityLabel: accessibilityLabel,
        updating: updating,
        disabled: disabled,
        action: action
      )
    }
  }
}

private struct BookProgressEditorSheet: View {
  let subjectId: Int
  let epsDesc: String
  let volumesDesc: String
  let initialEps: Int
  let initialVols: Int
  let reload: (() async -> Void)?

  @Environment(\.dismiss) private var dismiss

  @State private var eps: Int
  @State private var vols: Int
  @State private var updating = false

  init(subject: SubjectDTO, reload: (() async -> Void)?) {
    let initialEps = subject.interest?.epStatus ?? 0
    let initialVols = subject.interest?.volStatus ?? 0

    subjectId = subject.id
    epsDesc = subject.epsDesc
    volumesDesc = subject.volumesDesc
    self.initialEps = initialEps
    self.initialVols = initialVols
    self.reload = reload
    _eps = State(initialValue: initialEps)
    _vols = State(initialValue: initialVols)
  }

  private var hasChanges: Bool {
    eps != initialEps || vols != initialVols
  }

  private func update() {
    guard hasChanges, !updating else {
      return
    }

    updating = true
    Task {
      defer {
        updating = false
      }
      do {
        try await SubjectRepository.updateSubjectProgress(
          subjectId: subjectId,
          eps: eps == initialEps ? nil : eps,
          vols: vols == initialVols ? nil : vols
        )
        await reload?()
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        dismiss()
      } catch {
        Notifier.shared.alert(error: error)
      }
    }
  }

  var body: some View {
    SheetView(
      title: "更新阅读进度",
      size: .medium,
      closeDisabled: updating,
      applyFormStyle: true
    ) {
      Form {
        Section {
          BookProgressField(title: "话数", value: $eps, total: epsDesc)
          BookProgressField(title: "卷数", value: $vols, total: volumesDesc)
        }
      }
      .disabled(updating)
    } controls: {
      Button(action: update) {
        Text("更新")
          .opacity(updating ? 0 : 1)
          .overlay {
            if updating {
              ProgressView()
            }
          }
      }
      .disabled(!hasChanges || updating)
    }
    .tint(.accent)
  }
}

private struct BookProgressField: View {
  let title: LocalizedStringKey
  @Binding var value: Int
  let total: String

  var body: some View {
    LabeledContent(title) {
      HStack {
        TextField("进度", value: $value, format: .number)
          .keyboardType(.numberPad)
          .multilineTextAlignment(.trailing)
          .monospacedDigit()
          .frame(minWidth: 48, maxWidth: 72)
          .textFieldStyle(.roundedBorder)

        Text("/ \(total)")
          .foregroundStyle(.secondary)
          .monospacedDigit()

        Stepper(value: $value, in: 0...Int.max) {
          EmptyView()
        }
        .labelsHidden()
      }
    }
  }
}
