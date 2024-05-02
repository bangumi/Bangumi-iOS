//
//  LocalRow.swift
//  Chobits
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
          ImageView(img: subject.images.common, width: 60, height: 60)
          VStack(alignment: .leading) {
            Text(subject.name).font(.headline)
            Text(subject.nameCn).font(.subheadline).foregroundStyle(.secondary)
            HStack {
              Label(subject.type.description, systemImage: subject.type.icon).foregroundStyle(
                .accent)
              Text("\(subject.collectionTotal) 人收藏").foregroundStyle(.secondary)
              Label("\(subject.score.rateDisplay)", systemImage: "star").foregroundStyle(.secondary)
              Spacer()

              Text(collection.type.description(type: subject.type))
                .foregroundStyle(.accent)
                .overlay {
                  RoundedRectangle(cornerRadius: 5)
                    .stroke(.accent, lineWidth: 1)
                    .padding(.horizontal, -4)
                    .padding(.vertical, -2)
                }
            }.font(.caption)
          }
          Spacer()
        }
        .frame(height: 60)
        .padding(2)
        .clipShape(RoundedRectangle(cornerRadius: 10))
      }
    }
  }
}

#Preview {
  ScrollView {
    LazyVStack(alignment: .leading, spacing: 10) {
      SubjectSearchLocalRow(collection: .previewAnime)
    }
  }
  .padding(.horizontal, 16)
}
