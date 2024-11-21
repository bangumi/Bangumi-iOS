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
  let subjectId: UInt
  let compact: Bool

  @State private var inputEps: String = ""
  @State private var eps: UInt? = nil
  @State private var inputVols: String = ""
  @State private var vols: UInt? = nil
  @State private var updating: Bool = false

  @Query
  private var subjects: [Subject]
  private var subject: Subject? { subjects.first }

  @Query
  private var collections: [UserSubjectCollection]
  private var collection: UserSubjectCollection? { collections.first }

  init(subjectId: UInt, compact: Bool = false) {
    self.subjectId = subjectId
    _subjects = Query(
      filter: #Predicate<Subject> {
        $0.subjectId == subjectId
      })
    _collections = Query(
      filter: #Predicate<UserSubjectCollection> {
        $0.subjectId == subjectId
      })
    self.compact = compact
  }

  var updateButtonDisable: Bool {
    if updating {
      return true
    }
    return eps == nil && vols == nil
  }

  func parseInputEps() {
    if let newEps = UInt(inputEps) {
      self.eps = newEps
    } else {
      self.eps = nil
    }
  }

  func parseInputVols() {
    if let newVols = UInt(inputVols) {
      self.vols = newVols
    } else {
      self.vols = nil
    }
  }

  func incrEps() {
    if let value = eps {
      self.inputEps = "\(value+1)"
    } else {
      self.inputEps = "\(collectionEps+1)"
    }
  }

  func incrVols() {
    if let value = vols {
      self.inputVols = "\(value+1)"
    } else {
      self.inputVols = "\(collectionVols+1)"
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
        try await Chii.shared.updateBookCollection(subjectId: subjectId, eps: eps, vols: vols)
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
      } catch {
        Notifier.shared.alert(error: error)
      }
      self.reset()
      self.updating = false
    }
  }

  var collectionEps: UInt {
    guard let collection = self.collection else { return 0 }
    return collection.epStatus
  }

  var collectionVols: UInt {
    guard let collection = self.collection else { return 0 }
    return collection.volStatus
  }

  var body: some View {
    HStack {
      if compact {
        HStack(alignment: .firstTextBaseline, spacing: 0) {
          TextField("\(collectionEps)", text: $inputEps)
            .keyboardType(.numberPad)
            .frame(minWidth: 15, maxWidth: 30)
            .multilineTextAlignment(.trailing)
            .fixedSize(horizontal: true, vertical: false)
            .padding(.trailing, 2)
            .textFieldStyle(.plain)
            .onChange(of: inputEps){
              parseInputEps()
            }
          Text("/").foregroundStyle(.secondary)
          Text(subject?.epsDesc ?? "").foregroundStyle(.secondary)
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
          TextField("\(collectionVols)", text: $inputVols)
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
          Text(subject?.volumesDesc ?? "").foregroundStyle(.secondary)
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
            Button{
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
            TextField("\(collectionEps)", text: $inputEps)
              .keyboardType(.numberPad)
              .frame(minWidth: 50, maxWidth: 100)
              .multilineTextAlignment(.trailing)
              .fixedSize(horizontal: true, vertical: false)
              .padding(.trailing, 2)
              .textFieldStyle(.roundedBorder)
              .onChange(of: inputEps){
                parseInputEps()
              }
            Text("/").foregroundStyle(.secondary)
            Text(subject?.epsDesc ?? "").foregroundStyle(.secondary)
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
            TextField("\(collectionVols)", text: $inputVols)
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
            Text(subject?.volumesDesc ?? "").foregroundStyle(.secondary)
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
        VStack {
          if updating {
            ZStack {
              Button{
              } label: {
                Label("更新", systemImage: "checkmark")
              }
              .disabled(true)
              .hidden()
              .buttonStyle(.borderedProminent)
              ProgressView()
            }
          } else {
            Button {
              update()
            } label: {
              Label("更新", systemImage: "checkmark")
            }
            .disabled(updateButtonDisable)
            .buttonStyle(.borderedProminent)
          }
          Button {
            reset()
          } label: {
            Label("重置", systemImage: "arrow.counterclockwise")
          }
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

  return ScrollView {
    LazyVStack(alignment: .leading) {
      SubjectBookChaptersView(subjectId: subject.subjectId)
        .modelContainer(container)
    }
  }
  .padding()
}
