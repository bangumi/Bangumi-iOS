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

  @Environment(Notifier.self) private var notifier

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

  init(subjectId: UInt) {
    self.subjectId = subjectId
    _subjects = Query(
      filter: #Predicate<Subject> {
        $0.subjectId == subjectId
      })
    _collections = Query(
      filter: #Predicate<UserSubjectCollection> {
        $0.subjectId == subjectId
      })
  }

  var updateButtonDisable: Bool {
    if updating {
      return true
    }
    return eps == nil && vols == nil
  }

  func update() {
    self.updating = true
    Task {
      do {
        try await Chii.shared.updateBookCollection(sid: subjectId, eps: eps, vols: vols)
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
      } catch {
        notifier.alert(error: error)
      }
      self.eps = nil
      self.vols = nil
      self.inputEps = ""
      self.inputVols = ""
      self.updating = false
    }
  }

  var epsDesc: String {
    guard let subject = self.subject else { return "/?话" }
    return subject.eps > 0 ? "/\(subject.eps)话" : "/?话"
  }

  var volumesDesc: String {
    guard let subject = self.subject else { return "/?卷" }
    return subject.volumes > 0 ? "/\(subject.volumes)卷" : "/?卷"
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
      HStack(alignment: .firstTextBaseline, spacing: 0) {
        Button {
          if let value = eps {
            self.inputEps = "\(value+1)"
          } else {
            self.inputEps = "\(collectionEps+1)"
          }
        } label: {
          Image(systemName: "plus.circle")
            .foregroundStyle(.secondary)
            .padding(.trailing, 5)
        }.buttonStyle(.plain)
        TextField("\(collectionEps)", text: $inputEps)
          .keyboardType(.numberPad)
          .frame(minWidth: 48, maxWidth: 60)
          .multilineTextAlignment(.trailing)
          .fixedSize(horizontal: true, vertical: false)
          .padding(.trailing, 2)
          .textFieldStyle(.roundedBorder)
          .onChange(of: inputEps) {
            if let newEps = UInt(inputEps) {
              self.eps = newEps
            } else {
              self.eps = nil
            }
          }
        Text(epsDesc).foregroundStyle(.secondary)
      }.monospaced()
      HStack(alignment: .firstTextBaseline, spacing: 0) {
        Button {
          if let value = vols {
            self.inputVols = "\(value+1)"
          } else {
            self.inputVols = "\(collectionVols+1)"
          }
        } label: {
          Image(systemName: "plus.circle")
            .foregroundStyle(.secondary)
            .padding(.trailing, 5)
        }.buttonStyle(.plain)
        TextField("\(collectionVols)", text: $inputVols)
          .keyboardType(.numberPad)
          .frame(minWidth: 36, maxWidth: 48)
          .multilineTextAlignment(.trailing)
          .fixedSize(horizontal: true, vertical: false)
          .padding(.trailing, 2)
          .textFieldStyle(.roundedBorder)
          .onChange(of: inputVols) {
            if let newVols = UInt(inputVols) {
              self.vols = newVols
            } else {
              self.vols = nil
            }
          }
        Text(volumesDesc).foregroundStyle(.secondary)
      }.monospaced()
      Spacer()
      VStack {
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
    }.disabled(updating)
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
        .environment(Notifier())
        .modelContainer(container)
    }
  }
  .padding()
}
