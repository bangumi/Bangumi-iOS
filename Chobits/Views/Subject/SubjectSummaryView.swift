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

  var body: some View {
    VStack(alignment: .leading) {
      if subject.metaTags.count > 0 {
        HFlow(alignment: .center, spacing: 4) {
          ForEach(subject.metaTags, id: \.self) { tag in
            BorderView {
              Text(tag)
                .font(.footnote)
                .lineLimit(1)
            }.padding(1)
          }
        }
      }
      BBCodeWebView(subject.summary, textSize: 14)
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
