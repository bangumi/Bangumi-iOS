//
//  SubjectSummaryView.swift
//  Chobits
//
//  Created by Chuan Chuan on 2024/4/28.
//

import Flow
import OSLog
import SwiftData
import SwiftUI

struct SubjectSummaryView: View {
  @ObservableModel var subject: Subject

  @State private var showSummary = false

  var tags: [Tag] {
    return Array(subject.tags.sorted { $0.count > $1.count }.prefix(20))
  }

  var body: some View {
    VStack(alignment: .leading) {
      if subject.metaTags.count > 0 {
        HFlow(alignment: .center, spacing: 4) {
          ForEach(subject.metaTags, id: \.self) { tag in
            BorderView {
              Text(tag)
                .font(.footnote)
                .lineLimit(1)
            }
          }
        }
      }
      Text(subject.summary)
        .font(.footnote)
        .multilineTextAlignment(.leading)
        .lineLimit(5)
        .sheet(isPresented: $showSummary) {
          ScrollView {
            LazyVStack(alignment: .leading) {
              HFlow(alignment: .center, spacing: 2) {
                ForEach(tags, id: \.name) { tag in
                  BorderView {
                    HStack {
                      Text(tag.name)
                        .font(.footnote)
                        .lineLimit(1)
                      Text("\(tag.count)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    }
                  }.padding(1)
                }
              }.animation(.default, value: tags)
              Divider()
              BBCodeView(code:subject.summary)
              Divider()
            }.padding()
          }
        }
      HStack {
        Spacer()
        Button(action: {
          showSummary.toggle()
        }) {
          Text("more...")
            .font(.caption)
            .foregroundStyle(.linkText)
        }
      }
    }.padding(.vertical, 2)
  }
}

#Preview {
  let container = mockContainer()

  let subject = Subject.previewAnime
  container.mainContext.insert(subject)

  return ScrollView {
    LazyVStack(alignment: .leading) {
      SubjectSummaryView(subject: subject)
        .modelContainer(container)
    }
  }.padding()
}
