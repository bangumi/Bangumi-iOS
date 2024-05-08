//
//  SubjectBookChaptersView.swift
//  Chobits
//
//  Created by Chuan Chuan on 2024/5/2.
//

import SwiftData
import SwiftUI

struct SubjectBookChaptersView: View {
  let subjectId: UInt

  @EnvironmentObject var notifier: Notifier
  @EnvironmentObject var chii: ChiiClient

  @State private var eps: UInt?
  @State private var vols: UInt?
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
        $0.id == subjectId
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
        try await chii.updateBookCollection(sid: subjectId, eps: eps, vols: vols)
      } catch {
        notifier.alert(error: error)
      }
      self.eps = nil
      self.vols = nil
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
            self.eps = value + 1
          } else {
            self.eps = collectionEps + 1
          }
        } label: {
          Image(systemName: "plus.circle").foregroundStyle(.secondary).padding(.trailing, 5)
        }.buttonStyle(.plain)
        TextField("\(collectionEps)", value: $eps, formatter: NumberFormatter())
          .keyboardType(.numberPad)
          .frame(width: 50)
          .multilineTextAlignment(.trailing)
          .fixedSize(horizontal: true, vertical: false)
          .padding(.trailing, 5)
          .textFieldStyle(.roundedBorder)
        Text(epsDesc).foregroundStyle(.secondary)
      }.monospaced()
      Spacer()
      HStack(alignment: .firstTextBaseline, spacing: 0) {
        Button {
          if let value = vols {
            self.vols = value + 1
          } else {
            self.vols = collectionVols + 1
          }
        } label: {
          Image(systemName: "plus.circle").foregroundStyle(.secondary).padding(.trailing, 5)
        }.buttonStyle(.plain)
        TextField("\(collectionVols)", value: $vols, formatter: NumberFormatter())
          .keyboardType(.numberPad)
          .frame(width: 50)
          .multilineTextAlignment(.trailing)
          .fixedSize(horizontal: true, vertical: false)
          .padding(.trailing, 5)
          .textFieldStyle(.roundedBorder)
        Text(volumesDesc).foregroundStyle(.secondary)
      }.monospaced()
      Spacer()
      Button("更新", action: update)
        .disabled(updateButtonDisable)
        .buttonStyle(.borderedProminent)
    }.disabled(updating)
  }
}

#Preview {
  let config = ModelConfiguration(isStoredInMemoryOnly: true)
  let container = try! ModelContainer(
    for: UserSubjectCollection.self, Subject.self, configurations: config)

  let collection = UserSubjectCollection.previewBook
  let subject = Subject.previewBook

  container.mainContext.insert(collection)
  container.mainContext.insert(subject)

  return ScrollView {
    LazyVStack(alignment: .leading) {
      SubjectBookChaptersView(subjectId: subject.id)
        .environmentObject(Notifier())
        .environment(ChiiClient(container: container, mock: .book))
        .modelContainer(container)
    }
  }
  .padding()
}
