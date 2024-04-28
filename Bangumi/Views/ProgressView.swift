//
//  ProgressView.swift
//  Bangumi
//
//  Created by Chuan Chuan on 2024/4/19.
//

import SwiftData
import SwiftUI

struct ProgressView: View {
  @EnvironmentObject var errorHandling: ErrorHandling
  @EnvironmentObject var chiiClient: ChiiClient
  @EnvironmentObject var navState: NavState
  @Environment(\.modelContext) private var modelContext

  @Query(sort: \UserSubjectCollection.updatedAt, order: .reverse) private var collections: [UserSubjectCollection]

  @State private var subjectType = SubjectType.anime

  func updateCollections(type: SubjectType?) {
    Task.detached(priority: .background) {
      do {
        var offset: UInt = 0
        let limit: UInt = 100
        while true {
          let response = try await chiiClient.getCollections(subjectType: type, limit: limit, offset: offset)
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
        await errorHandling.handle(message: "\(error)")
      }
    }
  }

  var body: some View {
    if chiiClient.isAuthenticated {
      NavigationStack(path: $navState.progressNavigation) {
        if collections.isEmpty {
          LoadingView().onAppear {
            updateCollections(type: nil)
          }
        } else {
          VStack {
            Picker("Subject Type", selection: $subjectType) {
              ForEach(SubjectType.progressTypes()) { type in
                Text(type.description)
              }
            }.pickerStyle(.segmented)
            ScrollView {
              LazyVStack(alignment: .leading, spacing: 10) {
                let filtered = collections.filter { $0.subjectType == subjectType }
                ForEach(filtered) { collection in
                  NavigationLink(value: collection) {
                    UserCollectionRow(collection: collection)
                  }.buttonStyle(PlainButtonStyle())
                }
              }
            }
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
