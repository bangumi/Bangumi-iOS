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
  @Environment(\.modelContext) var modelContext

  @State private var refreshing: Bool = false
  @State private var refreshProgress: CGFloat = 0

  func refreshCollections() async {
    refreshing = true
    refreshProgress = 0
    var offset: Int = 0
    while true {
      do {
        guard let db = await Chii.shared.db else {
          throw ChiiError.uninitialized
        }
        let resp = try await Chii.shared.getSubjectCollections(
          collectionType: .unknown, subjectType: .unknown, offset: offset)
        if resp.data.isEmpty {
          break
        }
        for item in resp.data {
          try await db.saveUserCollection(item)
          if let slim = item.subject {
            try await db.saveSubject(slim)
          }
        }
        try await db.commit()
        Logger.collection.info(
          "loaded user collection: \(resp.data.count), offset: \(offset), total: \(resp.total)")
        offset += resp.data.count
        if offset >= resp.total {
          break
        }
        refreshProgress = CGFloat(offset) / CGFloat(resp.total)
      } catch {
        Notifier.shared.alert(error: error)
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
          ForEach(SubjectType.allTypes) { stype in
            VStack {
              HStack {
                Text("我的\(stype.description)").font(.title3)
                Spacer()
                NavigationLink(value: NavDestination.collectionList(subjectType: stype)) {
                  Text("更多 »")
                    .font(.caption)
                    .foregroundStyle(.linkText)
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
        .modelContainer(container)
    }
    .padding(.horizontal, 8)
  }
}
