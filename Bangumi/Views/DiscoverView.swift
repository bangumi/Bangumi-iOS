//
//  DiscoverView.swift
//  Bangumi
//
//  Created by Chuan Chuan on 2024/4/19.
//

import SwiftData
import SwiftUI

struct DiscoverView: View {
    @EnvironmentObject var chiiClient: ChiiClient

    @State private var query = ""
    @State private var local = true
    @Query private var collections: [UserSubjectCollection]

    var filterdCollections: [UserSubjectCollection] {
        if !local || query.isEmpty {
            return []
        }
        let filtered = collections.filter {
            if let subject = $0.subject {
                return subject.nameCn.lowercased().contains(query) || subject.name.lowercased().contains(query)
            } else {
                return false
            }
        }
        return Array(filtered.prefix(10))
    }

    var body: some View {
        NavigationStack {
            if query.isEmpty {
                // TODO:
                EmptyView()
            } else {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 10) {
                        ForEach(filterdCollections) { collection in
                            if let subject = collection.subject {
                                SubjectLocalSearchRow(subject: subject)
                            }
                        }
                    }
                }.padding()
            }
        }
        .searchable(text: $query)
        .onChange(of: query) { _, _ in
            local = true
        }
        .onSubmit(of: .search) {
            local = false
            print(query)
        }
    }
}
