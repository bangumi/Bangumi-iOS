//
//  Summary.swift
//  Chobits
//
//  Created by Chuan Chuan on 2024/4/28.
//

import SwiftUI

struct SubjectSummaryView: View {
  let subject: Subject

  @State private var collapsed = true

  var tags: [Tag] {
    Array(subject.tags.sorted { $0.count > $1.count }.prefix(20))
  }

  var body: some View {
    Text("简介").font(.headline)
    Text(subject.summary)
      .font(.footnote)
      .multilineTextAlignment(.leading)
      .lineLimit(collapsed ? 5 : nil)
      .animation(.default, value: collapsed)
    HStack {
      Spacer()
      Button {
        collapsed.toggle()
      } label: {
        if collapsed {
          Text("more")
        } else {
          Text("close")
        }
      }
      .buttonStyle(PlainButtonStyle())
      .font(.caption)
      .foregroundStyle(Color("LinkTextColor"))
    }
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
          RoundedRectangle(cornerRadius: 5)
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
      SubjectSummaryView(subject: .previewAnime)
    }
  }.padding()
}
