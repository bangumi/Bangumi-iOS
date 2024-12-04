//
//  SubjectBookChaptersView.swift
//  Chobits
//
//  Created by Chuan Chuan on 2024/5/2.
//

import Foundation
import SwiftData
import SwiftUI

struct SubjectBookChaptersView: View {
  let subjectId: Int
  let compact: Bool

  @Environment(\.modelContext) var modelContext

  @Query
  private var collections: [UserSubjectCollection]
  private var collection: UserSubjectCollection? { collections.first }

  @State private var inputEps: String = ""
  @State private var eps: Int? = nil
  @State private var inputVols: String = ""
  @State private var vols: Int? = nil
  @State private var updating: Bool = false

  init(subjectId: Int, compact: Bool = false) {
    self.subjectId = subjectId
    self.compact = compact

    let predicate = #Predicate<UserSubjectCollection> {
      $0.subjectId == subjectId
    }
    self._collections = Query(filter: predicate, sort: \UserSubjectCollection.subjectId)
  }

  var updateButtonDisable: Bool {
    if updating {
      return true
    }
    return eps == nil && vols == nil
  }

  var epsDesc: String {
    collection?.subject?.epsDesc ?? ""
  }

  var epStatus: Int {
    collection?.epStatus ?? 0
  }

  var volsDesc: String {
    collection?.subject?.volumesDesc ?? ""
  }

  var volStatus: Int {
    collection?.volStatus ?? 0
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
    guard let collection = collection else {
      return
    }
    if let value = eps {
      self.inputEps = "\(value+1)"
    } else {
      self.inputEps = "\(collection.epStatus+1)"
    }
  }

  func incrVols() {
    guard let collection = collection else {
      return
    }
    if let value = vols {
      self.inputVols = "\(value+1)"
    } else {
      self.inputVols = "\(collection.volStatus+1)"
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
          subjectId: subjectId, eps: eps, vols: vols)
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
      if compact {
        HStack(alignment: .firstTextBaseline, spacing: 0) {
          TextField("\(epStatus)", text: $inputEps)
            .keyboardType(.numberPad)
            .frame(minWidth: 15, maxWidth: 30)
            .multilineTextAlignment(.trailing)
            .fixedSize(horizontal: true, vertical: false)
            .padding(.trailing, 2)
            .textFieldStyle(.plain)
            .onChange(of: inputEps) {
              parseInputEps()
            }
          Text("/").foregroundStyle(.secondary)
          Text(epsDesc).foregroundStyle(.secondary)
          Text("话").foregroundStyle(.secondary)
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
          TextField("\(volStatus)", text: $inputVols)
            .keyboardType(.numberPad)
            .frame(minWidth: 15, maxWidth: 30)
            .multilineTextAlignment(.trailing)
            .fixedSize(horizontal: true, vertical: false)
            .padding(.trailing, 2)
            .textFieldStyle(.plain)
            .onChange(of: inputVols) {
              parseInputVols()
            }
          Text("/").foregroundStyle(.secondary)
          Text(volsDesc).foregroundStyle(.secondary)
          Text("卷").foregroundStyle(.secondary)
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
      } else {
        VStack {
          HStack(alignment: .firstTextBaseline, spacing: 0) {
            Text("Chap.").foregroundStyle(.secondary)
            TextField("\(epStatus)", text: $inputEps)
              .keyboardType(.numberPad)
              .frame(minWidth: 50, maxWidth: 100)
              .multilineTextAlignment(.trailing)
              .fixedSize(horizontal: true, vertical: false)
              .padding(.trailing, 2)
              .textFieldStyle(.roundedBorder)
              .onChange(of: inputEps) {
                parseInputEps()
              }
            Text("/").foregroundStyle(.secondary)
            Text(epsDesc).foregroundStyle(.secondary)
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
            TextField("\(volStatus)", text: $inputVols)
              .keyboardType(.numberPad)
              .frame(minWidth: 50, maxWidth: 100)
              .multilineTextAlignment(.trailing)
              .fixedSize(horizontal: true, vertical: false)
              .padding(.trailing, 2)
              .textFieldStyle(.roundedBorder)
              .onChange(of: inputVols) {
                parseInputVols()
              }
            Text("/").foregroundStyle(.secondary)
            Text(volsDesc).foregroundStyle(.secondary)
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
      }
    }
    .disabled(updating)
  }
}

#Preview {
  let container = mockContainer()

  let collection = UserSubjectCollection.previewBook
  let subject = Subject.previewBook

  container.mainContext.insert(collection)
  container.mainContext.insert(subject)
  collection.subject = subject

  return ScrollView {
    LazyVStack(alignment: .leading) {
      SubjectBookChaptersView(subjectId: collection.subjectId, compact: false)
        .modelContainer(container)
    }
  }
  .padding()
}
