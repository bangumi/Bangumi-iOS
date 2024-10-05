//
//  SubjectTopicListView.swift
//  Chobits
//
//  Created by Chuan Chuan on 2024/10/5.
//


import SwiftData
import SwiftUI

struct SubjectTopicListView: View {
  let subjectId: UInt

  @Environment(Notifier.self) private var notifier

  var body: some View {
    ScrollView {
      LazyVStack(alignment: .leading) {
        Text("🚧")
      }
    }
    .padding(.horizontal, 8)
    .buttonStyle(.plain)
//    .animation(.default, value: topics)
    .navigationTitle("讨论版")
    .navigationBarTitleDisplayMode(.inline)
    .toolbar {
      ToolbarItem(placement: .automatic) {
        Image(systemName: "list.bullet.circle").foregroundStyle(.secondary)
      }
    }
  }
}
