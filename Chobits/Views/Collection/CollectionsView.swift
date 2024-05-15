//
//  CollectionsView.swift
//  Chobits
//
//  Created by Chuan Chuan on 2024/5/14.
//

import OSLog
import SwiftData
import SwiftUI

struct CollectionsView: View {
  @EnvironmentObject var notifier: Notifier
  @EnvironmentObject var chii: ChiiClient
  @EnvironmentObject var navState: NavState
  @Environment(\.modelContext) var modelContext

  @State private var collections: [SubjectType: [CollectionType: [UserSubjectCollection]]] = [:]
  @State private var refreshing: Bool = false
  @State private var refreshProgress: CGFloat = 0

  func loadCollections() async {
    let fetcher = BackgroundFetcher(modelContext.container)
    for stype in SubjectType.allTypes() {
      for ctype in CollectionType.timelineTypes() {
        let stypeVal = stype.rawValue
        let ctypeVal = ctype.rawValue
        var descriptor = FetchDescriptor<UserSubjectCollection>(
          predicate: #Predicate<UserSubjectCollection> {
            $0.subjectType == stypeVal && $0.type == ctypeVal
          },
          sortBy: [
            SortDescriptor<UserSubjectCollection>(\.updatedAt, order: .reverse)
          ])
        descriptor.fetchLimit = 7
        do {
          let collects = try await fetcher.fetchData(descriptor)
          if collections[stype] == nil {
            collections[stype] = [ctype: collects]
          } else {
            collections[stype]?[ctype] = collects
          }
        } catch {
          notifier.alert(error: error)
        }
      }
    }
  }

  func refreshCollections() async {
    refreshing = true
    refreshProgress = 0
    var offset: Int = 0
    while true {
      do {
        let resp = try await chii.getSubjectCollections(
          collectionType: .unknown, subjectType: .unknown, offset: offset)
        if resp.data.isEmpty {
          break
        }
        for item in resp.data {
          let collection = UserSubjectCollection(item)
          await chii.db.insert(collection)
          if let slim = item.subject {
            let subject = Subject(slim)
            let subjectId = subject.subjectId
            try await chii.db.insertIfNeeded(
              data: subject,
              predicate: #Predicate<Subject> {
                $0.subjectId == subjectId
              })
          }
        }
        Logger.collection.info(
          "loaded user collection: \(resp.data.count), offset: \(offset), total: \(resp.total)")
        offset += resp.data.count
        if offset >= resp.total {
          break
        }
        try await chii.db.save()
        refreshProgress = CGFloat(offset) / CGFloat(resp.total)
      } catch {
        notifier.alert(error: error)
        break
      }
    }
    refreshing = false
    await loadCollections()
  }

  var body: some View {
    ScrollView(showsIndicators: false) {
      LazyVStack(alignment: .leading) {
        ForEach(SubjectType.allTypes()) { stype in
          HStack {
            NavigationLink(value: NavDestination.collectionList(subjectType: stype)) {
              Text("我的\(stype.description)")
                .font(.headline)
                .foregroundStyle(Color("LinkTextColor"))
            }.buttonStyle(.plain)
            Spacer()
          }.padding(.top, 8)
          Divider()
          ForEach(CollectionType.timelineTypes()) { ctype in
            if let collects = collections[stype]?[ctype], !collects.isEmpty {
              ScrollView(.horizontal, showsIndicators: false) {
                HStack(alignment: .top) {
                  VStack {
                    Spacer()
                    Text(ctype.description(type: stype)).foregroundStyle(.secondary)
                    Spacer()
                    Spacer()
                  }
                  ForEach(collects) { collect in
                    CollectionItemView(subjectId: collect.subjectId)
                  }
                }
              }
            }
          }
        }
        if refreshing {
          ProgressView(value: refreshProgress)
        } else {
          Button {
            Task {
              await refreshCollections()
            }
          } label: {
            HStack {
              Spacer()
              Text("刷新所有收藏")
              Spacer()
            }.padding()
          }
        }
        Spacer()
      }
    }
    .onAppear {
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
