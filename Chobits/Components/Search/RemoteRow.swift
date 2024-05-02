//
//  RemoteRow.swift
//  Chobits
//
//  Created by Chuan Chuan on 2024/4/26.
//

import SwiftUI

struct SubjectSearchRemoteRow: View {
  var subject: SearchSubject

  var body: some View {
    ZStack {
      Rectangle()
        .fill(.accent)
        .opacity(0.01)
        .frame(height: 64)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .shadow(color: .accent, radius: 1, x: 1, y: 1)
      HStack {
        ImageView(img: subject.image, width: 60, height: 60)
        VStack(alignment: .leading) {
          let score = String(format: "%.1f", subject.score)
          Text(subject.name).font(.headline)
          Text(subject.nameCn).font(.subheadline).foregroundStyle(.secondary)
          HStack {
            if let type = subject.type {
              Label(type.description, systemImage: type.icon).foregroundStyle(.accent)
            }
            if !subject.date.isEmpty {
              Label(subject.date, systemImage: "calendar").foregroundStyle(.secondary)
            }
            Spacer()
            if subject.rank > 0 {
              Label("\(subject.rank)", systemImage: "chart.bar.xaxis").foregroundStyle(.accent)
            }
            if subject.score > 0 {
              Label("\(score)", systemImage: "star").foregroundStyle(.secondary)
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
      SubjectSearchRemoteRow(subject: .previewAnime)
    }
  }
  .padding(.horizontal, 16)
}
