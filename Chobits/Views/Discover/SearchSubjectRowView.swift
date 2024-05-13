//
//  ProgressRowView.swift
//  Chobits
//
//  Created by Chuan Chuan on 2024/4/26.
//

import SwiftUI

struct SearchSubjectRowView: View {
  let subject: Subject

  var body: some View {
    HStack {
      ImageView(img: subject.images.common, width: 60, height: 60, type: .subject)
      VStack(alignment: .leading) {
        Text(subject.name).font(.headline)
        Text(subject.nameCn).font(.subheadline).foregroundStyle(.secondary)
        HStack(alignment: .bottom) {
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
            Label("\(subject.rating.score.rateDisplay)", systemImage: "star.fill")
              .foregroundStyle(
                .accent)
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

#Preview {
  ScrollView {
    LazyVStack(alignment: .leading, spacing: 10) {
      SearchSubjectRowView(subject: Subject.previewAnime)
    }
  }
  .padding(.horizontal, 8)
}
