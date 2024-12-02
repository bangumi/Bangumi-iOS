//
//  SubjectInfoboxView.swift
//  Chobits
//
//  Created by Chuan Chuan on 2024/5/9.
//

import Flow
import SwiftData
import SwiftUI

struct SubjectInfoboxView: View {
  @ObservableModel var subject: Subject

  var body: some View {
    ScrollView {
      LazyVStack(alignment: .leading) {
        ForEach(subject.infobox, id: \.key) { item in
          HStack(alignment: .top) {
            Text("\(item.key): ").bold()
            VStack(alignment: .leading) {
              ForEach(item.values, id: \.v) { value in
                if let k = value.k {
                  HStack {
                    Text("\(k) ").foregroundStyle(.secondary)
                    Text(value.v)
                  }
                } else {
                  Text(value.v)
                }
              }
            }
          }
          Divider()
        }
      }
      .padding()
      .navigationTitle("条目信息")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .automatic) {
          Image(systemName: "info.circle").foregroundStyle(.secondary)
        }
      }
    }
  }
}

#Preview {
  let container = mockContainer()

  let subject = Subject.previewAnime
  container.mainContext.insert(subject)

  return SubjectInfoboxView(subject: subject)
    .modelContainer(container)
}
