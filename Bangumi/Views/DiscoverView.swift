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

    @State private var searching = false
    @State private var query = ""
    @State private var local = true
    @State private var subjectType: SubjectType = .unknown
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
            if searching {
                Picker("Subject Type", selection: $subjectType) {
                    Text("全部").tag(SubjectType.unknown)
                    ForEach(SubjectType.searchTypes()) { type in
                        Text(type.description).tag(type)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 16)
                if query.isEmpty {
                    // TODO:
                    EmptyView()
                } else {
                    if local {
                        ScrollView {
                            LazyVStack(alignment: .leading, spacing: 10) {
                                ForEach(filterdCollections) { collection in
                                    if let subject = collection.subject {
                                        if subjectType == .unknown || subjectType == subject.type {
                                            SubjectSearchLocalRow(subject: subject)
                                        }
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                    } else {
                        ScrollView {
                            LazyVStack(alignment: .leading, spacing: 10) {
                                // TODO:
                            }
                        }
                        .padding(.horizontal, 16)
                    }
                }
                Spacer()
            } else {
                // TODO:
                EmptyView()
            }
        }
        .searchable(text: $query, isPresented: $searching)
        .onChange(of: query) { _, _ in
            local = true
        }
        .onSubmit(of: .search) {
            local = false
        }
    }
}
