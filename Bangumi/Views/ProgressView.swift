//
//  ProgressView.swift
//  Bangumi
//
//  Created by Chuan Chuan on 2024/4/19.
//

import SwiftData
import SwiftUI

struct ProgressView: View {
    @EnvironmentObject var chiiClient: ChiiClient
    @EnvironmentObject var errorHandling: ErrorHandling
    @Environment(\.modelContext) private var modelContext

    @Query private var profiles: [Profile]
    @Query(sort: \UserSubjectCollection.updatedAt, order: .reverse) private var collections: [UserSubjectCollection]

    private var profile: Profile? { profiles.first }

    @State private var subjectType = SubjectType.anime

    var body: some View {
        switch profile {
        case .some(let me):
            if collections.isEmpty {
                Text("Updating collections...").onAppear {
                    Task.detached {
                        do {
                            try await chiiClient.updateCollections(profile: me, subjectType: nil)
                        } catch {
                            await errorHandling.handle(message: "\(error)")
                        }
                    }
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
                                UserCollectionRow(collection: collection)
                            }
                        }
                    }.refreshable {
                        Task.detached(priority: .background) {
                            do {
                                try await chiiClient.updateCollections(profile: me, subjectType: subjectType)
                            } catch {
                                await errorHandling.handle(message: "\(error)")
                            }
                        }
                    }
                }.padding()
            }
        case .none:
            Text("Refreshing profile...").onAppear {
                Task.detached {
                    do {
                        try await chiiClient.updateProfile()
                    } catch {
                        await errorHandling.handle(message: "\(error)")
                    }
                }
            }
        }
    }
}
