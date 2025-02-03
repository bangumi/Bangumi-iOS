import Foundation
import SwiftData
import SwiftUI

enum BookChapterMode {
  case large
  case row
  case tile
}

struct SubjectBookChaptersView: View {
  let mode: BookChapterMode

  @Environment(Subject.self) var subject

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
      self.inputEps = "\(subject.interest?.epStatus ?? 0+1)"
    }
  }

  func incrVols() {
    if let value = vols {
      self.inputVols = "\(value+1)"
    } else {
      self.inputVols = "\(subject.interest?.volStatus ?? 0+1)"
    }
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
        try await Chii.shared.updateBookCollection(
          subjectId: subject.subjectId, eps: eps, vols: vols)
        _ = try await Chii.shared.loadSubject(subject.subjectId)

        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
      } catch {
        Notifier.shared.alert(error: error)
      }
      self.reset()
      self.updating = false
    }
  }

  var body: some View {
    HStack {
      switch mode {
      case .large:
        VStack {
          HStack(alignment: .firstTextBaseline, spacing: 0) {
            Text("Chap.").foregroundStyle(.secondary)
            TextField("\(subject.interest?.epStatus ?? 0)", text: $inputEps)
              .keyboardType(.numberPad)
              .frame(minWidth: 50, maxWidth: 75)
              .multilineTextAlignment(.trailing)
              .fixedSize(horizontal: true, vertical: false)
              .padding(.trailing, 2)
              .textFieldStyle(.roundedBorder)
              .onChange(of: inputEps) {
                parseInputEps()
              }
            Text("/").foregroundStyle(.secondary)
            Text(subject.epsDesc).foregroundStyle(.secondary)
              .padding(.trailing, 5)
            Button {
              incrEps()
            } label: {
              Image(systemName: "plus.circle")
                .foregroundStyle(.secondary)
            }.buttonStyle(.plain)
            Spacer()
          }.monospaced()
          HStack(alignment: .firstTextBaseline, spacing: 0) {
            Text("Vol. ").foregroundStyle(.secondary)
            TextField("\(subject.interest?.volStatus ?? 0)", text: $inputVols)
              .keyboardType(.numberPad)
              .frame(minWidth: 50, maxWidth: 75)
              .multilineTextAlignment(.trailing)
              .fixedSize(horizontal: true, vertical: false)
              .padding(.trailing, 2)
              .textFieldStyle(.roundedBorder)
              .onChange(of: inputVols) {
                parseInputVols()
              }
            Text("/").foregroundStyle(.secondary)
            Text(subject.volumesDesc).foregroundStyle(.secondary)
              .padding(.trailing, 5)
            Button {
              incrVols()
            } label: {
              Image(systemName: "plus.circle")
                .foregroundStyle(.secondary)
            }.buttonStyle(.plain)
            Spacer()
          }.monospaced()
        }
        Spacer()
        if updating {
          ZStack {
            Button("更新", action: {})
              .disabled(true)
              .hidden()
              .buttonStyle(.borderedProminent)
            ProgressView()
          }
        } else {
          Button("更新", action: update)
            .disabled(updateButtonDisable)
            .buttonStyle(.borderedProminent)
        }
      case .row:
        HStack {
          HStack(alignment: .firstTextBaseline, spacing: 0) {
            TextField("\(subject.interest?.epStatus ?? 0)", text: $inputEps)
              .keyboardType(.numberPad)
              .frame(minWidth: 15, maxWidth: 30)
              .multilineTextAlignment(.trailing)
              .fixedSize(horizontal: true, vertical: false)
              .padding(.trailing, 2)
              .textFieldStyle(.plain)
              .onChange(of: inputEps) {
                parseInputEps()
              }
            Text("/\(subject.epsDesc)话")
              .foregroundStyle(.secondary)
              .padding(.trailing, 2)
            Button {
              incrEps()
            } label: {
              Image(systemName: "plus.circle")
                .foregroundStyle(.secondary)
            }.buttonStyle(.plain)
          }
          .monospaced()
          HStack(alignment: .firstTextBaseline, spacing: 0) {
            TextField("\(subject.interest?.volStatus ?? 0)", text: $inputVols)
              .keyboardType(.numberPad)
              .frame(minWidth: 15, maxWidth: 30)
              .multilineTextAlignment(.trailing)
              .fixedSize(horizontal: true, vertical: false)
              .padding(.trailing, 2)
              .textFieldStyle(.plain)
              .onChange(of: inputVols) {
                parseInputVols()
              }
            Text("/\(subject.volumesDesc)卷")
              .foregroundStyle(.secondary)
              .padding(.trailing, 2)
            Button {
              incrVols()
            } label: {
              Image(systemName: "plus.circle")
                .foregroundStyle(.secondary)
            }.buttonStyle(.plain)
          }
          .monospaced()
          Spacer()
          if updating {
            ZStack {
              Button {
              } label: {
                Image(systemName: "checkmark.circle")
              }
              .disabled(true)
              .hidden()
              .buttonStyle(.plain)
              ProgressView()
            }
          } else {
            Button {
              update()
            } label: {
              Image(systemName: "checkmark.circle")
            }
            .disabled(updateButtonDisable)
            .buttonStyle(.borderless)
          }
        }.font(.callout)
      case .tile:
        HStack {
          Spacer()
          VStack(alignment: .trailing) {
            HStack(alignment: .firstTextBaseline, spacing: 0) {
              TextField("\(subject.interest?.epStatus ?? 0)", text: $inputEps)
                .keyboardType(.numberPad)
                .frame(minWidth: 32, maxWidth: 48)
                .multilineTextAlignment(.trailing)
                .fixedSize(horizontal: true, vertical: false)
                .padding(.trailing, 2)
                .textFieldStyle(.plain)
                .onChange(of: inputEps) {
                  parseInputEps()
                }
              Text("/\(subject.epsDesc)话")
                .foregroundStyle(.secondary)
                .padding(.trailing, 2)
              Button {
                incrEps()
              } label: {
                Image(systemName: "plus.circle")
                  .foregroundStyle(.secondary)
              }.buttonStyle(.plain)
            }.monospaced()
            HStack(alignment: .firstTextBaseline, spacing: 0) {
              TextField("\(subject.interest?.volStatus ?? 0)", text: $inputVols)
                .keyboardType(.numberPad)
                .frame(minWidth: 32, maxWidth: 48)
                .multilineTextAlignment(.trailing)
                .fixedSize(horizontal: true, vertical: false)
                .padding(.trailing, 2)
                .textFieldStyle(.plain)
                .onChange(of: inputVols) {
                  parseInputVols()
                }
              Text("/\(subject.volumesDesc)卷")
                .foregroundStyle(.secondary)
                .padding(.trailing, 2)
              Button {
                incrVols()
              } label: {
                Image(systemName: "plus.circle")
                  .foregroundStyle(.secondary)
              }.buttonStyle(.plain)
            }.monospaced()
          }
          VStack {
            if updating {
              ZStack {
                Button {
                } label: {
                  Image(systemName: "checkmark.circle")
                }
                .font(.title3)
                .disabled(true)
                .hidden()
                .buttonStyle(.plain)
                ProgressView()
              }
            } else {
              Button {
                update()
              } label: {
                Image(systemName: "checkmark.circle")
              }
              .font(.title3)
              .disabled(updateButtonDisable)
              .buttonStyle(.borderless)
            }
          }
        }
      }
    }.disabled(updating)
  }
}

#Preview {
  let container = mockContainer()

  let subject = Subject.previewBook
  container.mainContext.insert(subject)

  return ScrollView {
    LazyVStack(alignment: .leading) {
      SubjectBookChaptersView(mode: .large)
        .environment(subject)
      SubjectBookChaptersView(mode: .row)
        .environment(subject)
      HStack(spacing: 8) {
        SubjectBookChaptersView(mode: .tile)
          .environment(subject)
        Spacer()
        SubjectBookChaptersView(mode: .tile)
          .environment(subject)
      }
    }.padding()
  }.modelContainer(container)
}
