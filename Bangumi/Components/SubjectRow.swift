//
//  SubjectRow.swift
//  Bangumi
//
//  Created by Chuan Chuan on 2024/4/24.
//

import SwiftUI

struct SubjectRow: View {
    var subject: SlimSubject

    var body: some View {
        let iconURL = URL(string: subject.images.common)
        HStack {
            CachedAsyncImage(url: iconURL) { image in
                image.resizable().scaledToFill().frame(width: 64, height: 64).clipped()
            } placeholder: {
                Rectangle().fill(.accent.opacity(0.1)).frame(width: 64, height: 64)
            }
            VStack(alignment: .leading) {
                let score = String(format: "%.1f", subject.score)
                Text(subject.name).font(.headline)
                Text(subject.nameCn).font(.subheadline).foregroundStyle(.gray)
                HStack {
                    Label(subject.type.description, systemImage: subject.type.icon).foregroundStyle(.accent)
                    Text("\(subject.collectionTotal) 人收藏").foregroundStyle(.gray)
                    Spacer()
                    Label("\(score)", systemImage: "star").foregroundStyle(.gray)
                }.font(.caption)
            }
            Spacer()
        }
        .frame(height: 64)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}
