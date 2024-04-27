//
//  SubjectSearchLocalRow.swift
//  Bangumi
//
//  Created by Chuan Chuan on 2024/4/24.
//

import SwiftUI

struct SubjectSearchLocalRow: View {
  var collection: UserSubjectCollection

  var body: some View {
    if let subject = collection.subject {
      ZStack {
        Rectangle()
          .fill(.accent)
          .opacity(0.01)
          .frame(height: 64)
          .clipShape(RoundedRectangle(cornerRadius: 10))
          .shadow(color: .accent, radius: 1, x: 1, y: 1)
        HStack {
          ImageView(img: subject.images.common, size: 60)
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
        .frame(height: 60)
        .padding(2)
        .clipShape(RoundedRectangle(cornerRadius: 10))
      }
    } else {
      EmptyView()
    }
  }
}
