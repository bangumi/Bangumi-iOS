//
//  Tag.swift
//  Chobits
//
//  Created by Chuan Chuan on 2024/4/28.
//

import SwiftUI

struct SubjectTagView: View {
  var subject: Subject

  var body: some View {
    let tags = subject.tags.sorted { $0.count > $1.count }.prefix(20)
    FlowStack {
      ForEach(tags, id: \.name) { tag in
        HStack {
          Text(tag.name)
            .font(.caption)
            .foregroundStyle(Color("LinkTextColor"))
            .lineLimit(1)
          Text("\(tag.count)")
            .font(.caption2)
            .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 4)
        .overlay {
          RoundedRectangle(cornerRadius: 4)
            .stroke(Color.secondary, lineWidth: 1)
            .padding(.horizontal, 2)
            .padding(.vertical, 2)
        }
      }
    }
  }
}

#Preview {
  ScrollView {
    LazyVStack(alignment: .leading) {
      SubjectTagView(subject: .previewAnime)
    }
  }.padding()
}
