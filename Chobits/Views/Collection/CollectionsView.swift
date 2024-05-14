//
//  CollectionsView.swift
//  Chobits
//
//  Created by Chuan Chuan on 2024/5/14.
//

import SwiftData
import SwiftUI

struct CollectionsView: View {
  @EnvironmentObject var notifier: Notifier
  @EnvironmentObject var chii: ChiiClient
  @EnvironmentObject var navState: NavState
  @Environment(\.modelContext) var modelContext

  @State private var collections: [SubjectType: [CollectionType: [UserSubjectCollection]]] = [:]

  func loadCollections() async {
    let fetcher = BackgroundFetcher(modelContext.container)
    for stype in SubjectType.allTypes() {
      for ctype in CollectionType.timelineTypes() {
        let stypeVal = stype.rawValue
        let ctypeVal = ctype.rawValue
        let descriptor = FetchDescriptor<UserSubjectCollection>(
          predicate: #Predicate<UserSubjectCollection> {
            $0.subjectType == stypeVal && $0.type == ctypeVal
          },
          sortBy: [
            SortDescriptor<UserSubjectCollection>(\.updatedAt, order: .reverse)
          ])
        do {
          let collects = try await fetcher.fetchData(descriptor)
          if var cs = collections[stype] {
            cs[ctype] = collects
          } else {
            collections[stype] = [ctype: collects]
          }
        } catch {
          notifier.alert(error: error)
        }
      }
    }
  }

  var body: some View {
    VStack(alignment: .leading) {
      ForEach(SubjectType.allTypes()) { stype in
        HStack {
          Text("我的\(stype.description)")
          Spacer()
        }
        ForEach(CollectionType.timelineTypes()) { ctype in
          if let collects = collections[stype]?[ctype] {
            HStack {
              Text(ctype.description(type: stype))
              ForEach(collects) { collect in
                Text("\(collect.subjectId)")
              }
            }
          }
        }
      }
      Spacer()
    }.onAppear {
      Task {
        await loadCollections()
      }
    }
  }
}

#Preview {
  let container = mockContainer()

  return NavigationStack {
    ScrollView {
      CollectionsView()
        .environmentObject(Notifier())
        .environment(ChiiClient(container: container, mock: .anime))
        .environmentObject(NavState())
        .modelContainer(container)
    }
    .padding(.horizontal, 8)
  }
}
