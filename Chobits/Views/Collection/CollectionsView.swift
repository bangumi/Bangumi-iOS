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

  @State private var refreshing: Bool = false
  @State private var refreshProgress: CGFloat = 0

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
  }

  var body: some View {

    if refreshing {
      VStack {
        Spacer().containerRelativeFrame([.vertical])
        ProgressView(value: refreshProgress)
        Spacer().containerRelativeFrame([.vertical])
      }.padding()
    } else {
      ScrollView(showsIndicators: false) {
        LazyVStack(alignment: .leading) {
          ForEach(SubjectType.allTypes()) { stype in
            VStack {
              HStack {
                Text("我的\(stype.description)").font(.title3)
                Spacer()
                NavigationLink(value: NavDestination.collectionList(subjectType: stype)) {
                  Text("更多 »")
                    .font(.caption)
                    .foregroundStyle(Color("LinkTextColor"))
                }.buttonStyle(.plain)
              }.padding(.top, 8)
              CollectionSubjectTypeView(stype: stype)
            }.padding(.top, 5)
          }
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
