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
  let collection: UserSubjectCollection

  @EnvironmentObject var notifier: Notifier
  @EnvironmentObject var chii: ChiiClient
  @Environment(\.modelContext) private var modelContext

  @State private var eps: UInt?
  @State private var vols: UInt?
  @State private var updating: Bool = false

  func update() {
    self.updating = true
    let actor = BackgroundActor(container: modelContext.container)
    Task {
      do {
        let item = try await chii.updateSubjectCollection(sid: subject.id, eps: eps, vols: vols)
        let collect = UserSubjectCollection(item: item)
        await actor.insert(data: collect)
        try await actor.save()
      } catch {
        notifier.alert(error: error)
      }
      self.eps = nil
      self.vols = nil
      self.updating = false
    }
  }

  var epsDesc: String {
    return subject.eps > 0 ? "/\(subject.eps)话" : "/?话"
  }

  var volumesDesc: String {
    return subject.volumes > 0 ? "/\(subject.volumes)卷" : "/?卷"
  }

  var body: some View {
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
        Text(epsDesc).foregroundStyle(.secondary)
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
        Text(volumesDesc).foregroundStyle(.secondary)
      }.monospaced()
      Spacer()
      Button("更新", action: update)
        .buttonStyle(.borderedProminent)
    }.disabled(updating)
  }
}

#Preview {
  let config = ModelConfiguration(isStoredInMemoryOnly: true)
  let container = try! ModelContainer(for: UserSubjectCollection.self, configurations: config)
  container.mainContext.insert(UserSubjectCollection.previewBook)

  return ScrollView {
    LazyVStack(alignment: .leading) {
      SubjectCollectionBookView(subject: .previewBook, collection: .previewBook)
        .environmentObject(Notifier())
        .environmentObject(ChiiClient(mock: .book))
    }
  }
  .padding()
  .modelContainer(container)
}
