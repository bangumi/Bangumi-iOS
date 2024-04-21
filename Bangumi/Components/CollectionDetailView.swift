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
            let gridURL = URL(string: subject.images.grid)
            VStack(alignment: .leading) {
                HStack(alignment: .top) {
                    CachedAsyncImage(url: gridURL) { image in
                        image.resizable().scaledToFill().frame(width: 100, height: 100).clipShape(RoundedRectangle(cornerRadius: 10)).clipped()
                    } placeholder: {
                        Image(systemName: "photo").frame(width: 100, height: 100)
                    }
                    VStack(alignment: .leading) {
                        Text(subject.nameCn).font(.caption).foregroundStyle(.gray).multilineTextAlignment(.leading)
                            .lineLimit(2)
                        Text(subject.name).font(.headline).multilineTextAlignment(.leading)
                            .lineLimit(2)
                        Label(collection.type.description, systemImage: collection.type.icon).font(.caption).foregroundStyle(.accent)
                    }
                }
                Text("章节").font(.headline)
                Text("简介").font(.headline)
                Text(subject.shortSummary).font(.caption).multilineTextAlignment(.leading)

            }.padding([.horizontal], 10)
        } else {
            EmptyView()
        }
    }
}
