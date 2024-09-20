//
//  CollectionSubjectTypeView.swift
//  Chobits
//
//  Created by Chuan Chuan on 2024/5/24.
//

import SwiftData
import SwiftUI

struct CollectionSubjectTypeView: View {
  let stype: SubjectType

  @Environment(Notifier.self) private var notifier
  @Environment(ChiiClient.self) private var chii
  @Environment(\.modelContext) var modelContext

  @State private var collectionType: CollectionType = .collect
  @State private var counts: [CollectionType: Int] = [:]
  @State private var collections: [UserSubjectCollection] = []
  @State private var subjects: [UInt: Subject] = [:]

  func load() async {
    let stypeVal = stype.rawValue
    let ctypeVal = collectionType.rawValue
    var descriptor = FetchDescriptor<UserSubjectCollection>(
      predicate: #Predicate<UserSubjectCollection> {
        $0.subjectType == stypeVal && $0.type == ctypeVal
      },
      sortBy: [
        SortDescriptor<UserSubjectCollection>(\.updatedAt, order: .reverse)
      ])
    descriptor.fetchLimit = 10
    do {
      collections = try modelContext.fetch(descriptor)
      for collection in collections {
        let sid = collection.subjectId
        var desc = FetchDescriptor<Subject>(
          predicate: #Predicate<Subject> {
            $0.subjectId == sid
          })
        desc.fetchLimit = 1
        let res = try modelContext.fetch(desc)
        let subject = res.first
        subjects[sid] = subject
      }
    } catch {
      notifier.alert(error: error)
    }
  }

  func loadCounts() async {
    let stypeVal = stype.rawValue
    do {
      for type in CollectionType.allTypes() {
        let ctypeVal = type.rawValue
        let desc = FetchDescriptor<UserSubjectCollection>(
          predicate: #Predicate<UserSubjectCollection> {
            $0.type == ctypeVal && $0.subjectType == stypeVal
          })
        let count = try modelContext.fetchCount(desc)
        counts[type] = count
      }
    } catch {
      notifier.alert(error: error)
    }
  }

  var body: some View {
    VStack {
      Picker("Collection Type", selection: $collectionType) {
        ForEach(CollectionType.allTypes()) { ctype in
          Text("\(ctype.description(type: stype))(\(counts[ctype, default: 0]))").tag(
            ctype)
        }
      }
      .pickerStyle(.segmented)
      .onChange(of: collectionType) { _, _ in
        Task {
          await load()
        }
      }
      .onAppear {
        Task {
          await load()
          await loadCounts()
        }
      }
      if collections.count > 0 {
        LazyVGrid(columns: [
          GridItem(.flexible()),
          GridItem(.flexible()),
          GridItem(.flexible()),
          GridItem(.flexible()),
          GridItem(.flexible()),
        ]) {
          ForEach(collections) { collection in
            NavigationLink(value: NavDestination.subject(subjectId: collection.subjectId)) {
              ImageView(
                img: subjects[collection.subjectId]?.images.common, width: 60, height: 60,
                type: .subject)
            }.buttonStyle(.plain)
          }
        }
      }
    }
    .animation(.default, value: collections)
  }
}

#Preview {
  let container = mockContainer()

  return NavigationStack {
    ScrollView {
      CollectionSubjectTypeView(stype: .anime)
        .environment(Notifier())
        .environment(ChiiClient(container: container, mock: .anime))
        .modelContainer(container)
    }
    .padding(.horizontal, 8)
  }
}
