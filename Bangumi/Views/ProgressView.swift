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
    @Query(sort: \UserSubjectCollection.updatedAt) private var collections: [UserSubjectCollection]

    private var profile: Profile? { profiles.first }

    @State private var subjectType = SubjectType.anime

    var body: some View {
        switch profile {
        case .some(let me):
            if collections.isEmpty {
                Text("Updating collections...").onAppear {
                    Task {
                        do {
                            try await chiiClient.updateCollections(profile: me)
                        } catch {
                            errorHandling.handle(message: "\(error)")
                        }
                    }
                }
            } else {
                VStack {
                    Picker("Subject Type", selection: $subjectType) {
                        ForEach(SubjectType.progressTypes()) { type in
                            Text(type.description)
                        }
                    }
                    .pickerStyle(.segmented)
                    List {
                        ForEach(collections) { collection in
                            if collection.subjectType == subjectType {
                                UserCollectionRow(collection: collection)
                            }
                        }
                    }
                }
            }
        case .none:
            Text("Refreshing profile...").onAppear {
                Task {
                    do {
                        try await chiiClient.updateProfile()
                    } catch {
                        errorHandling.handle(message: "\(error)")
                    }
                }
            }
        }
    }
}

#Preview {
    ProgressView()
}
