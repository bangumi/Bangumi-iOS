//
//  Summary.swift
//  Chobits
//
//  Created by Chuan Chuan on 2024/4/28.
//

import SwiftUI

struct SubjectSummaryView: View {
  var subject: Subject

  @State private var collapsed = true

  var body: some View {
    VStack(alignment: .leading) {
      Text("简介").font(.headline)
      Text(subject.summary)
        .font(.footnote)
        .multilineTextAlignment(.leading)
        .lineLimit(collapsed ? 5 : nil)
      HStack {
        Spacer()
        Button {
          withAnimation {
            collapsed.toggle()
          }
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
    }
  }
}

#Preview {
  ScrollView {
    LazyVStack(alignment: .leading) {
      SubjectSummaryView(subject: .preview)
    }
  }.padding()
}
