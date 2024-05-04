//
//  CollectionBook.swift
//  Chobits
//
//  Created by Chuan Chuan on 2024/5/2.
//

import SwiftData
import SwiftUI

struct SubjectCollectionBookView: View {
  let subject: Subject

  @EnvironmentObject var notifier: Notifier
  @EnvironmentObject var chii: ChiiClient
  @Environment(\.modelContext) private var modelContext

  @State private var eps: UInt?
  @State private var vols: UInt?
  @State private var updating: Bool = false

  @Query
  private var collections: [UserSubjectCollection]
  private var collection: UserSubjectCollection? { collections.first }

  init(subject: Subject) {
    self.subject = subject
    let predicate = #Predicate<UserSubjectCollection> { collection in
      collection.subjectId == subject.id
    }
    _collections = Query(filter: predicate)
  }

  func update() {
    self.updating = true
    let actor = BackgroundActor(container: modelContext.container)
    Task {
      do {
        let resp = try await chii.updateSubjectCollection(sid: subject.id, eps: eps, vols: vols)
        await actor.insert(data: resp)
        try await actor.save()
      } catch {
        notifier.alert(error: error)
      }
      self.eps = nil
      self.vols = nil
      self.updating = false
    }
  }

  var body: some View {
    if let collection = collection {
      HStack {
        HStack(alignment: .firstTextBaseline, spacing: 0) {
          Button {
            if let value = eps {
              self.eps = value + 1
            } else {
              self.eps = collection.epStatus + 1
            }
          } label: {
            Image(systemName: "plus.circle").foregroundStyle(.secondary).padding(.trailing, 5)
          }.buttonStyle(.plain)
          TextField("\(collection.epStatus)", value: $eps, formatter: NumberFormatter())
            .keyboardType(.numberPad)
            .frame(width: 50)
            .multilineTextAlignment(.trailing)
            .fixedSize(horizontal: true, vertical: false)
            .padding(.trailing, 5)
            .textFieldStyle(.roundedBorder)
          Text(subject.eps > 0 ? "/\(subject.eps)话" : "/?话").foregroundStyle(.secondary)
        }.monospaced()
        Spacer()
        HStack(alignment: .firstTextBaseline, spacing: 0) {
          Button {
            if let value = vols {
              self.vols = value + 1
            } else {
              self.vols = collection.volStatus + 1
            }
          } label: {
            Image(systemName: "plus.circle").foregroundStyle(.secondary).padding(.trailing, 5)
          }.buttonStyle(.plain)
          TextField("\(collection.volStatus)", value: $vols, formatter: NumberFormatter())
            .keyboardType(.numberPad)
            .frame(width: 50)
            .multilineTextAlignment(.trailing)
            .fixedSize(horizontal: true, vertical: false)
            .padding(.trailing, 5)
            .textFieldStyle(.roundedBorder)
          Text(subject.volumes > 0 ? "/\(subject.volumes)卷" : "/?卷").foregroundStyle(.secondary)
        }.monospaced()
        Spacer()
        Button("更新", action: update)
          .buttonStyle(.borderedProminent)
      }.disabled(updating)
    }
  }
}

#Preview {
  let config = ModelConfiguration(isStoredInMemoryOnly: true)
  let container = try! ModelContainer(for: UserSubjectCollection.self, configurations: config)
  container.mainContext.insert(UserSubjectCollection.previewBook)

  return ScrollView {
    LazyVStack(alignment: .leading) {
      SubjectCollectionBookView(subject: .previewBook)
        .environmentObject(Notifier())
        .environmentObject(ChiiClient(mock: .book))
    }
  }
  .padding()
  .modelContainer(container)
}
