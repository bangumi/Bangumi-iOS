//
//  UserCollectionRow.swift
//  Bangumi
//
//  Created by Chuan Chuan on 2024/4/21.
//

import SwiftUI

struct UserCollectionRow: View {
    var collection: UserSubjectCollection

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
                    image.resizable().scaledToFill().frame(width: 48, height: 48).clipped()
                } placeholder: {
                    Image(systemName: "photo").frame(width: 48, height: 48)
                }
                switch collection.subjectType {
                case .anime:
                    VStack(alignment: .leading) {
                        Text(subject.name).bold()
                        Text(subject.nameCn).font(.caption).foregroundStyle(.gray)
                        Text(chapters).font(.caption).foregroundStyle(.accent)
                    }
                case .book:
                    VStack(alignment: .leading) {
                        Text(subject.name).bold()
                        Text(subject.nameCn).font(.caption).foregroundStyle(.gray)
                        Text("\(chapters)  \(volumes)").font(.caption).foregroundStyle(.accent)
                    }
                case .real:
                    VStack(alignment: .leading) {
                        Text(subject.name).bold()
                        Text(subject.nameCn).font(.caption).foregroundStyle(.gray)
                        Text(chapters).font(.caption).foregroundStyle(.accent)
                    }
                default:
                    Text(subject.name).bold()
                }
            }.frame(height: 48)
        } else {
            EmptyView()
        }
    }
}

// #Preview {
//    UserCollectionRow(collection: collections[0])
// }
