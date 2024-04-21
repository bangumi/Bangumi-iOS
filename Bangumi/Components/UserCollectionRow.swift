//
//  UserCollectionRow.swift
//  Bangumi
//
//  Created by Chuan Chuan on 2024/4/21.
//

import SwiftUI

struct UserCollectionRow: View {
    var collection: UserSubjectCollection
    @State private var showDetail = false

    var body: some View {
        if let subject = collection.subject {
            let gridURL = URL(string: subject.images.grid)
            let chapters = if subject.eps > 0 {
                "\(collection.epStatus)/\(subject.eps) 话"
            } else {
                "\(collection.epStatus)/? 话"
            }
            let volumes = if subject.volumes > 0 {
                "\(collection.volStatus)/\(subject.volumes) 卷"
            } else {
                "\(collection.volStatus)/? 卷"
            }
            HStack {
                CachedAsyncImage(url: gridURL) { image in
                    image.resizable().scaledToFill().frame(width: 64, height: 64).clipped()
                } placeholder: {
                    Image(systemName: "photo").frame(width: 64, height: 64)
                }
                switch collection.subjectType {
                case .anime:
                    VStack(alignment: .leading) {
                        Text(subject.name).bold()
                        Text(subject.nameCn).font(.caption).foregroundStyle(.gray)
                        Text(chapters).font(.caption).foregroundStyle(.accent)
                        Text(collection.updatedAt.formatted()).font(.caption2).foregroundStyle(.gray)
                    }
                case .book:
                    VStack(alignment: .leading) {
                        Text(subject.name).bold()
                        Text(subject.nameCn).font(.caption).foregroundStyle(.gray)
                        Text("\(chapters)  \(volumes)").font(.caption).foregroundStyle(.accent)
                        Text(collection.updatedAt.formatted()).font(.caption2).foregroundStyle(.gray)
                    }
                case .real:
                    VStack(alignment: .leading) {
                        Text(subject.name).bold()
                        Text(subject.nameCn).font(.caption).foregroundStyle(.gray)
                        Text(chapters).font(.caption).foregroundStyle(.accent)
                        Text(collection.updatedAt.formatted()).font(.caption2).foregroundStyle(.gray)
                    }
                default:
                    Text(subject.name).bold()
                }
            }
            .frame(height: 64)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .onTapGesture {
                showDetail = true
            }
            .scaleEffect(showDetail ? 1.1 : 1)
            .shadow(color: .accent, radius: showDetail ? 5 : 0)
            .animation(.spring(), value: showDetail)
            .sheet(isPresented: $showDetail) {
                CollectionDetailView(collection: collection).presentationDetents([.medium, .large]).presentationDragIndicator(.visible)
            }
        } else {
            EmptyView()
        }
    }
}
