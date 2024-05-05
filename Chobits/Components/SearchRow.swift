//
//  SearchRow.swift
//  Chobits
//
//  Created by Chuan Chuan on 2024/4/26.
//

import SwiftUI

struct SubjectSearchRow: View {
  let subject: Subject

  var body: some View {
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
            Label(subject.typeEnum.description, systemImage: subject.typeEnum.icon).foregroundStyle(
              .accent)
            if subject.date.timeIntervalSince1970 > 0 {
              Label(subject.date.formatAirdate, systemImage: "calendar").foregroundStyle(.secondary)
            }
            Spacer()
            if subject.rating.rank > 0 {
              Label("\(subject.rating.rank)", systemImage: "chart.bar.xaxis").foregroundStyle(
                .accent)
            }
            if subject.rating.score > 0 {
              Label("\(subject.rating.score.rateDisplay)", systemImage: "star").foregroundStyle(
                .secondary)
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

#Preview {
  ScrollView {
    LazyVStack(alignment: .leading, spacing: 10) {
      SubjectSearchRow(subject: .previewAnime)
    }
  }
  .padding(.horizontal, 16)
}
