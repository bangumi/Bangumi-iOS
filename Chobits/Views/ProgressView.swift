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

  @Query(sort: \UserSubjectCollection.updatedAt, order: .reverse) private var collections: [UserSubjectCollection]

  @State private var subjectType = SubjectType.unknown

  func updateCollections(type: SubjectType?) {
    Task.detached(priority: .background) {
      do {
        var offset: UInt = 0
        let limit: UInt = 100
        while true {
          let response = try await chii.getCollections(subjectType: type, limit: limit, offset: offset)
          if response.data.isEmpty {
            break
          }
          await MainActor.run {
            withAnimation {
              for collect in response.data {
                modelContext.insert(collect)
              }
            }
          }
          offset += 100
          if offset > response.total {
            break
          }
        }
      } catch {
        await notifier.alert(message: "\(error)")
      }
    }
  }

  var doing: [SubjectType:[UserSubjectCollection]] {
    let filtered = collections.filter{
      $0.type == .do
    }
    var doing = Dictionary(grouping: filtered, by: { $0.subjectType })
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
            .animation(.smooth, value: subjectType)
            .navigationDestination(for: UserSubjectCollection.self) { collection in
              SubjectView(sid: collection.subjectId)
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
