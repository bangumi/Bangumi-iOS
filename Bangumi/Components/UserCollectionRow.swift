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
            ZStack {
                Rectangle()
                    .fill(.accent)
                    .opacity(showDetail ? 0.05 : 0.01)
                    .frame(height: 64)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .shadow(color: .accent, radius: 1, x: 1, y: 1)
                HStack {
                    ImageView(img: subject.images.common, size: 60)
                    VStack(alignment: .leading) {
                        Text(subject.name).font(.headline)
                        Text(subject.nameCn).font(.subheadline).foregroundStyle(.gray)
                        switch collection.subjectType {
                        case .anime:
                            HStack {
                                Text(collection.updatedAt.formatted()).foregroundStyle(.gray)
                                Spacer()
                                Text(chapters).foregroundStyle(.accent)
                            }.font(.caption)
                        case .book:
                            HStack {
                                Text(collection.updatedAt.formatted()).foregroundStyle(.gray)
                                Spacer()
                                Text("\(chapters)  \(volumes)").foregroundStyle(.accent)
                            }.font(.caption)
                        case .real:
                            HStack {
                                Text(collection.updatedAt.formatted()).foregroundStyle(.gray)
                                Spacer()
                                Text(chapters).foregroundStyle(.accent)
                            }.font(.caption)
                        default:
                            HStack {
                                Text(collection.updatedAt.formatted()).foregroundStyle(.gray)
                                Spacer()
                            }.font(.caption)
                        }
                    }
                    Spacer()
                }
                .frame(height: 60)
                .padding(2)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .onTapGesture {
                    showDetail = true
                }
                .animation(.spring(), value: showDetail)
                .sheet(isPresented: $showDetail) {
                    CollectionDetailView(collection: collection).presentationDetents([.medium, .large]).presentationDragIndicator(.visible)
                }
            }
        } else {
            EmptyView()
        }
    }
}
