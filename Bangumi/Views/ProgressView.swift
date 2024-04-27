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

  @Query private var profiles: [Profile]
  @Query(sort: \UserSubjectCollection.updatedAt, order: .reverse) private var collections: [UserSubjectCollection]

  private var profile: Profile? { profiles.first }

  @State private var subjectType = SubjectType.anime

  func updateCollections(profile: Profile, type: SubjectType?) {
    Task.detached(priority: .background) {
      do {
        try await chiiClient.updateCollections(profile: profile, subjectType: type)
      } catch {
        await errorHandling.handle(message: "\(error)")
      }
    }
  }

  func updateProfile() {
    Task.detached {
      do {
        try await chiiClient.updateProfile()
      } catch {
        await errorHandling.handle(message: "\(error)")
      }
    }
  }

  var body: some View {
    NavigationStack(path: $navState.progressNavigation) {
      switch profile {
      case .some(let me):
        if collections.isEmpty {
          VStack {
            Text("Updating collections...")
          }
          .onAppear {
            updateCollections(profile: me, type: nil)
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
              updateCollections(profile: me, type: subjectType)
            }
          }.padding()
        }
      case .none:
        Text("Refreshing profile...").onAppear(perform: updateProfile)
      }
    }
  }
}
