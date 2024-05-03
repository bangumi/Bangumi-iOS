//
//  ProgressView.swift
//  Chobits
//
//  Created by Chuan Chuan on 2024/4/19.
//

import SwiftData
import SwiftUI

struct ChiiProgressView: View {
  @EnvironmentObject var notifier: Notifier
  @EnvironmentObject var chii: ChiiClient
  @EnvironmentObject var navState: NavState

  @Environment(\.modelContext) private var modelContext

  @Query(sort: \UserSubjectCollection.updatedAt, order: .reverse) private var collections:
    [UserSubjectCollection]

  @State private var subjectType = SubjectType.unknown

  func updateCollections(type: SubjectType?) {
    let actor = BackgroundActor(container: modelContext.container)
    Task {
      do {
        var offset: Int = 0
        let limit: Int = 100
        while true {
          let response = try await chii.getSubjectCollections(
            subjectType: type, limit: limit, offset: offset)
          if response.data.isEmpty {
            break
          }
          for collection in response.data {
            await actor.insert(data: collection, background: true)
          }
          offset += limit
          if offset > response.total {
            break
          }
        }
        try await actor.save()
      } catch {
        notifier.alert(message: "\(error)")
      }
    }
  }

  var doing: [SubjectType: [UserSubjectCollection]] {
    let filtered = collections.filter {
      $0.typeEnum == .do
    }
    var doing = Dictionary(grouping: filtered, by: { $0.subjectTypeEnum })
    doing[.unknown] = filtered
    return doing
  }

  var body: some View {
    if chii.isAuthenticated {
      NavigationStack(path: $navState.progressNavigation) {
        if collections.isEmpty {
          ProgressView().onAppear {
            updateCollections(type: nil)
          }
        } else {
          VStack {
            Picker("Subject Type", selection: $subjectType) {
              ForEach(SubjectType.progressTypes()) { type in
                Text("\(type.description)(\(doing[type]?.count ?? 0))")
              }
            }.pickerStyle(.segmented)
            ScrollView {
              LazyVStack(alignment: .leading, spacing: 10) {
                ForEach(doing[subjectType] ?? []) { collection in
                  NavigationLink(value: collection) {
                    UserCollectionRow(collection: collection)
                  }.buttonStyle(PlainButtonStyle())
                }
              }
            }
            .animation(.easeInOut, value: subjectType)
            .navigationDestination(for: UserSubjectCollection.self) { collection in
              SubjectView(subjectId: collection.subjectId)
            }
            .refreshable {
              updateCollections(type: subjectType)
            }
          }.padding()
        }
      }
    } else {
      AuthView(slogan: "使用 Bangumi 管理观看进度")
    }
  }
}
