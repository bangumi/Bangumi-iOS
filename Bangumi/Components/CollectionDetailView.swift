//
//  CollectionDetailView.swift
//  Bangumi
//
//  Created by Chuan Chuan on 2024/4/21.
//

import SwiftUI

struct CollectionDetailView: View {
    var collection: UserSubjectCollection

    var body: some View {
        if let subject = collection.subject {
            VStack {
                Text(subject.name).font(.title)
                Text(subject.nameCn).font(.title2)
            }
        } else {
            EmptyView()
        }
    }
}
