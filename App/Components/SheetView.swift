import SwiftUI

enum SheetPresentationSize {
  case medium
  case large
  case both

  var detents: Set<PresentationDetent> {
    switch self {
    case .medium:
      [.medium]
    case .large:
      [.large]
    case .both:
      [.medium, .large]
    }
  }
}

struct SheetView<Content: View, Controls: View>: View {
  let title: String?
  let size: SheetPresentationSize
  let closeTitle: String
  let showsCloseButton: Bool
  let closeDisabled: Bool
  let onClose: (() -> Void)?
  let controlsPlacement: ToolbarItemPlacement
  let applyFormStyle: Bool
  let content: Content
  let controls: Controls?

  @Environment(\.dismiss) private var dismiss

  init(
    title: String? = nil,
    size: SheetPresentationSize = .large,
    closeTitle: String = "取消",
    showsCloseButton: Bool = true,
    closeDisabled: Bool = false,
    onClose: (() -> Void)? = nil,
    controlsPlacement: ToolbarItemPlacement = .confirmationAction,
    applyFormStyle: Bool = false,
    @ViewBuilder content: () -> Content,
    @ViewBuilder controls: () -> Controls
  ) {
    self.title = title
    self.size = size
    self.closeTitle = closeTitle
    self.showsCloseButton = showsCloseButton
    self.closeDisabled = closeDisabled
    self.onClose = onClose
    self.controlsPlacement = controlsPlacement
    self.applyFormStyle = applyFormStyle
    self.content = content()
    self.controls = controls()
  }

  init(
    title: String? = nil,
    size: SheetPresentationSize = .large,
    closeTitle: String = "取消",
    showsCloseButton: Bool = true,
    closeDisabled: Bool = false,
    onClose: (() -> Void)? = nil,
    applyFormStyle: Bool = false,
    @ViewBuilder content: () -> Content
  ) where Controls == EmptyView {
    self.title = title
    self.size = size
    self.closeTitle = closeTitle
    self.showsCloseButton = showsCloseButton
    self.closeDisabled = closeDisabled
    self.onClose = onClose
    controlsPlacement = .confirmationAction
    self.applyFormStyle = applyFormStyle
    self.content = content()
    controls = nil
  }

  var body: some View {
    NavigationStack {
      sheetContent
        .navigationTitle(title ?? "")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
          if showsCloseButton {
            ToolbarItem(placement: .cancellationAction) {
              Button {
                onClose?()
                dismiss()
              } label: {
                Label(closeTitle, systemImage: "xmark")
              }
              .disabled(closeDisabled)
            }
          }
          if let controls {
            ToolbarItemGroup(placement: controlsPlacement) {
              controls
            }
          }
        }
    }
    .presentationDetents(size.detents)
  }

  @ViewBuilder
  private var sheetContent: some View {
    if applyFormStyle {
      content
        .formStyle(.grouped)
        .scrollContentBackground(.hidden)
    } else {
      content
    }
  }
}
