//
//  TimelineView.swift
//  Chobits
//
//  Created by Chuan Chuan on 2024/4/19.
//

import SwiftData
import SwiftUI

struct ChiiTimelineView: View {
  @AppStorage("isolationMode") var isolationMode: Bool = false

  @Environment(Notifier.self) private var notifier
  @Environment(ChiiClient.self) private var chii

  var body: some View {
    VStack {
      if chii.isAuthenticated {
        CollectionsView()
          .padding(.horizontal, 8)
      } else {
        AuthView(slogan: "Bangumi 让你的 ACG 生活更美好")
      }
    }
  }
}

#Preview {
  let container = mockContainer()
  return ChiiTimelineView()
    .environment(Notifier())
    .environment(ChiiClient(container: container, mock: .anime))
    .modelContainer(container)
}
